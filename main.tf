provider "aws" {
    region = var.aws_region
}

module "jenkinssg" {
  source  = "app.terraform.io/kevindemos/jenkinssg/aws"
  version = "1.0.4"

  aws_region = var.aws_region
}
