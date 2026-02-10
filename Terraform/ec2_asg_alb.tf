# Par de chaves para SSH no bastion
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.deployer.public_key_openssh
}

# ALB
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Modelo de lançamento para instâncias web
data "template_file" "web_user_data" {
  template = file("${path.module}/user_data/web_userdata.sh.tpl")

  vars = {
    bucket_name  = aws_s3_bucket.backup.id
    kms_key_arn  = aws_kms_key.backup_key.arn
    region       = var.region
    project_name = var.project_name
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.project_name}-web-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.web_instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  key_name = aws_key_pair.deployer_key.key_name != "" ? aws_key_pair.deployer_key.key_name : null

  network_interfaces {
    security_groups             = [aws_security_group.web_sg.id]
    associate_public_ip_address = false
  }

  user_data = base64encode(data.template_file.web_user_data.rendered)
  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-web" }
  }
}

# Grupo de Auto Scaling
resource "aws_autoscaling_group" "web_asg" {
  name                = "${var.project_name}-asg"
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  vpc_zone_identifier = aws_subnet.private_web[*].id
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }
  target_group_arns         = [aws_lb_target_group.web_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# AMI (Ubuntu 22.04 LTS)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Bastion
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  key_name = aws_key_pair.deployer_key.key_name != "" ? aws_key_pair.deployer_key.key_name : null

  user_data = base64encode(templatefile("${path.module}/user_data/bastion_userdata.sh.tpl", {
    region = var.region
  }))

  tags = { Name = "${var.project_name}-bastion" }
}

