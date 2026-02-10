resource "local_sensitive_file" "deployer_private_key" {
  # Avoid overwriting an existing key file (can be locked by editors on Windows).
  # In a fresh checkout, the file won't exist and Terraform will create it.
  count    = fileexists("${path.module}/bastion.pem") ? 0 : 1
  filename = "${path.module}/bastion.pem"
  content  = tls_private_key.deployer.private_key_pem

  directory_permission = "0700"
  file_permission      = "0600"
}
