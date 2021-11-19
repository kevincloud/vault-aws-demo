provider "aws" {
    region = var.aws_region
}

# module "jenkinssg" {
#     source  = "app.terraform.io/kevindemos/jenkinssg/aws"
#     version = "1.0.6"

#     aws_region = var.aws_region
#     vpcid = aws_vpc.main-vpc.id
#     prefix = var.prefix
#     owner = var.owner
#     se-region = var.se-region
#     purpose = var.purpose
#     ttl = var.ttl
#     terraform = var.terraform
# }
