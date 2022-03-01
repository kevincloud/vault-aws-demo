# Create a vault server

resource "aws_instance" "vault-server" {
    count = var.num_nodes
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.vault-server-sg.id]
    subnet_id = aws_subnet.public-subnet.id
    private_ip = "10.0.10.${count.index + 21}"
    user_data = templatefile("${path.module}/scripts/vault_install.sh", {
        NODE_INDEX = count.index + 1
        NUM_NODES = var.num_nodes
        AMI_ID = data.aws_ami.ubuntu.id
        AWS_REGION = var.aws_region
        MYSQL_HOST = aws_db_instance.vault-mysql.endpoint
        MYSQL_DBNAME = var.mysql_dbname
        POSTGRES_HOST = aws_db_instance.vault-postgres.endpoint
        POSTGRES_DBNAME = "${var.prefix}${var.postgres_dbname}"
        DB_USER = var.db_user
        DB_PASS = var.db_pass
        AWS_KMS_KEY_ID =  aws_kms_key.vault.id
        VAULT_URL = var.vault_dl_url
        VAULT_LICENSE = var.vault_license
        CTPL_URL = var.consul_tpl_url
        GIT_BRANCH = var.git_branch
        AUTOJOIN_KEY = var.autojoin_key
        AUTOJOIN_VALUE = var.autojoin_value
        # TF_API_TOKEN = var.tf_api_token
        # JENKINS_ARN = aws_iam_role.jenkins-main-access-role.arn
        ROLE_ARN = aws_iam_role.vault-ec2-allow-demo-role.arn
    })
    iam_instance_profile = aws_iam_instance_profile.vault-demo.id
    
    tags = {
        Name = "${var.prefix}-vault-unseal-demo-${count.index}"
        NodeID = "Node${count.index + 1}"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
        "${var.autojoin_key}" = var.autojoin_value
    }
}

resource "aws_security_group" "vault-server-sg" {
    name = "${var.prefix}-vault-server-sg"
    description = "Vault security group"
    vpc_id = aws_vpc.main-vpc.id

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

    ingress {
        from_port = 8201
        to_port = 8201
        protocol = "tcp"
        cidr_blocks = ["10.0.10.0/24"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    tags = {
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
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

data "aws_iam_policy_document" "vault-demo" {
  statement {
    sid       = "VaultDemo"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "iam:GetRole",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2messages:GetMessages",
      "ssm:UpdateInstanceInformation",
      "ssm:ListInstanceAssociations",
      "ssm:ListAssociations",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "s3:*",
      "rds:*"
    ]
  }
}

resource "aws_iam_role" "vault-demo-role" {
    name               = "${var.prefix}-vault-demo-role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
    
    tags = {
        Name = "${var.prefix}-vault-iam-role"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_iam_role_policy" "vault-demo" {
    name   = "${var.prefix}-vault-demo"
    role   = aws_iam_role.vault-demo-role.id
    policy = data.aws_iam_policy_document.vault-demo.json
}

resource "aws_iam_instance_profile" "vault-demo" {
    name = "${var.prefix}-vault-demo"
    role = aws_iam_role.vault-demo-role.name
    
    tags = {
        Name = "${var.prefix}-vault-instance-profile"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}
