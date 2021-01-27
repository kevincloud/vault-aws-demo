terraform {
  required_version = ">= 0.14"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "remote" {
    organization = "kevindemos"

    workspaces {
      name = "vault-aws-demo"
    }
  }
}
