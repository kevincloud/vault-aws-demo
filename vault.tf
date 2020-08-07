# Create a vault server

resource "aws_instance" "vault-server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.vault-server-sg.id]
    user_data = templatefile("${path.module}/scripts/vault_install.sh", {
        AWS_ACCESS_KEY = var.aws_access_key
        AWS_SECRET_KEY = var.aws_secret_key
        AWS_SESSION_TOKEN = var.aws_session_token
        AMI_ID = data.aws_ami.ubuntu.id
        AWS_REGION = var.aws_region
        MYSQL_HOST = aws_db_instance.vault-mysql.endpoint
        MYSQL_USER = var.mysql_user
        MYSQL_PASS = var.mysql_pass
        AWS_KMS_KEY_ID = var.kms_key_id
        VAULT_URL = var.vault_dl_url
        VAULT_LICENSE = var.vault_license
        CTPL_URL = var.consul_tpl_url
        GIT_BRANCH = var.git_branch
    })
    iam_instance_profile = aws_iam_instance_profile.vault-kms-unseal.id
    
    tags = {
        Name = "${var.prefix}-vault-unseal-demo"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}

resource "aws_security_group" "vault-server-sg" {
    name = "${var.prefix}-vault-server-sg"
    description = "webserver security group"
    vpc_id = data.aws_vpc.primary-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8200
        to_port = 8200
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    tags = {
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault-kms-unseal" {
  statement {
    sid       = "VaultKMSUnseal"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
  }
}

resource "aws_iam_role" "vault-kms-unseal" {
    name               = "${var.prefix}-vault-demo-kms-role-unseal"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
    
    tags = {
        Name = "${var.prefix}-vault-iam-role"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}

resource "aws_iam_role_policy" "vault-kms-unseal" {
    name   = "${var.prefix}-vault-demo-kms-unseal"
    role   = aws_iam_role.vault-kms-unseal.id
    policy = data.aws_iam_policy_document.vault-kms-unseal.json
}

resource "aws_iam_instance_profile" "vault-kms-unseal" {
    name = "${var.prefix}-vault-demo-kms-unseal"
    role = aws_iam_role.vault-kms-unseal.name
}
