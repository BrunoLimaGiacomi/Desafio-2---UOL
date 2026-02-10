terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

data "http" "my_public_ip" {
  url = "https://api.ipify.org"
}

locals {
  detected_my_ip_cidr = "${trimspace(data.http.my_public_ip.response_body)}/32"
  ssh_ingress_cidr    = coalesce(var.my_ip, local.detected_my_ip_cidr)
}
