#!/bin/bash
set -e
REGION="${region}"
BUCKET="${bucket_name}"
KMS_KEY="${kms_key_arn}"

# atualizar + instalar
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx awscli python3-pip auditd

# hardening
#  - desativar tokens do servidor
sed -i 's/server_tokens on;/server_tokens off;/' /etc/nginx/nginx.conf || true
# Adicionar cabeçalhos de segurança no bloco de servidor padrão
cat > /etc/nginx/conf.d/security_headers.conf <<'EOF'
add_header X-Frame-Options "DENY";
add_header X-Content-Type-Options "nosniff";
add_header Referrer-Policy "no-referrer";
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
EOF

cat > /var/www/html/index.html <<'EOF'
<html><head><title>HelloWorld</title></head><body><h1>Hello World</h1></body></html>
EOF

# configurar logrotate
cat > /etc/logrotate.d/nginx-custom <<'EOF'
/var/log/nginx/*.log {
  daily
  missingok
  rotate 7
  compress
  notifempty
  create 0640 www-data adm
  sharedscripts
  postrotate
    invoke-rc.d nginx rotate >/dev/null 2>&1 || true
  endscript
}
EOF

systemctl enable auditd
systemctl restart auditd

systemctl enable nginx
systemctl restart nginx

# Instalar e configurar o agente do CloudWatch (básico)
mkdir -p /opt/aws/amazon-cloudwatch-agent/bin
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<'CWCFG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/${project_name}/nginx/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/${project_name}/nginx/error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CWCFG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s || true

# script de backup para enviar /etc/nginx ao S3 usando SSE-KMS
cat > /usr/local/bin/backup_nginx_configs.sh <<'SCRIPT'
#!/bin/bash
set -e
TS=$(date -u +"%Y%m%dT%H%M%SZ")
HOST=$(hostname -f)
tar -C /etc -czf /tmp/nginx-conf-$TS-$HOST.tar.gz nginx || true
aws s3 cp /tmp/nginx-conf-$TS-$HOST.tar.gz s3://$BUCKET/nginx-backups/ --sse aws:kms --sse-kms-key-id $KMS_KEY --region $REGION
rm -f /tmp/nginx-conf-$TS-$HOST.tar.gz
SCRIPT

chmod +x /usr/local/bin/backup_nginx_configs.sh

# Criar tarefa do cron para rodar o backup diariamente
echo "0 2 * * * root /usr/local/bin/backup_nginx_configs.sh >/dev/null 2>&1" > /etc/cron.d/nginx_backup

