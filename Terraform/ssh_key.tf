resource "local_sensitive_file" "deployer_private_key" {
  filename = "${path.module}/bastion.pem"
  content  = tls_private_key.deployer.private_key_pem
}

