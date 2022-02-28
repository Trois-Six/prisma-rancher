terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1.0"
    }
  }

  required_version = ">= 0.15"
}

provider "aws" {
  region = var.aws_region
}

provider "tls" {}
