#!/bin/bash
# mínimo: permitir SSM + manter ativo
apt-get update -y
apt-get install -y awscli
# o agente SSM será instalado pela política AmazonSSMManagedInstanceCore + agente da distro quando disponivel
