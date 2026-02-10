variable "my_ip" {
  description = "Seu IP público para acesso ao SSH (CIDR)"
  type        = string
  default     = null

  validation {
    condition     = var.my_ip == null || can(cidrnetmask(var.my_ip))
    error_message = "my_ip must be a valid CIDR, e.g. 203.0.113.10/32."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.0.0/24", "10.10.1.0/24"] # 2 AZs para recursos públicos (ALB, Bastion)
}

variable "private_web_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.10.0/24", "10.10.11.0/24"] # 2 AZs para o ASG de web
}

variable "private_db_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.20.0/24", "10.10.21.0/24"] # sub-redes de BD (duas AZs recomendadas para o grupo de sub-redes)
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "web_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 2
}

variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "project_name" {
  type    = string
  default = "iac-desafio"
}
