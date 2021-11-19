resource "aws_instance" "vault-ec2-deny" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.vault-ec2-sg.id]
    subnet_id = aws_subnet.public-subnet.id
    user_data = templatefile("${path.module}/scripts/ec2_install.sh", {
        VAULT_IP = aws_instance.vault-server[0].public_ip
        AWS_REGION = var.aws_region
    })
    iam_instance_profile = aws_iam_instance_profile.vault-ec2-deny-demo.id

    tags = {
        Name = "${var.prefix}-vault-ec2-deny"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_instance" "vault-ec2-allow" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.vault-ec2-sg.id]
    subnet_id = aws_subnet.public-subnet.id
    user_data = templatefile("${path.module}/scripts/ec2_install.sh", {
        VAULT_IP = aws_instance.vault-server[0].public_ip
        AWS_REGION = var.aws_region
    })
    iam_instance_profile = aws_iam_instance_profile.vault-ec2-allow-demo.id
    
    tags = {
        Name = "${var.prefix}-vault-ec2-allow"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_security_group" "vault-ec2-sg" {
    name = "${var.prefix}-vault-ec2-sg"
    description = "ec2-vault security group"
    vpc_id = aws_vpc.main-vpc.id

    ingress {
        from_port = 22
        to_port = 22
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
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

data "aws_iam_policy_document" "assume-ec2-role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault-ec2-demo" {
  statement {
    sid       = "VaultAllowDenyDemo"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2messages:GetMessages",
      "ssm:UpdateInstanceInformation",
      "ssm:ListInstanceAssociations",
      "ssm:ListAssociations"
    ]
  }
}

###
# EC2 IAM for Deny access
###

resource "aws_iam_role" "vault-ec2-deny-demo-role" {
    name               = "${var.prefix}-vault-ec2-deny-demo-role"
    assume_role_policy = data.aws_iam_policy_document.assume-ec2-role.json
    
    tags = {
        Name = "${var.prefix}-vault-ec2-deny-iam-role"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_iam_role_policy" "vault-ec2-deny-demo" {
    name   = "${var.prefix}-vault-ec2-deny-demo"
    role   = aws_iam_role.vault-ec2-deny-demo-role.id
    policy = data.aws_iam_policy_document.vault-ec2-demo.json
}

resource "aws_iam_instance_profile" "vault-ec2-deny-demo" {
    name = "${var.prefix}-vault-ec2-deny-demo"
    role = aws_iam_role.vault-ec2-deny-demo-role.name
    
    tags = {
        Name = "${var.prefix}-vault-ec2-deny-instance-profile"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

###
# EC2 IAM for Allow access
###

resource "aws_iam_role" "vault-ec2-allow-demo-role" {
    name               = "${var.prefix}-vault-ec2-allow-demo-role"
    assume_role_policy = data.aws_iam_policy_document.assume-ec2-role.json
    
    tags = {
        Name = "${var.prefix}-vault-ec2-allow-iam-role"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_iam_role_policy" "vault-ec2-allow-demo" {
    name   = "${var.prefix}-vault-ec2-allow-demo"
    role   = aws_iam_role.vault-ec2-allow-demo-role.id
    policy = data.aws_iam_policy_document.vault-ec2-demo.json
}

resource "aws_iam_instance_profile" "vault-ec2-allow-demo" {
    name = "${var.prefix}-vault-ec2-allow-demo"
    role = aws_iam_role.vault-ec2-allow-demo-role.name
    
    tags = {
        Name = "${var.prefix}-vault-ec2-allow-instance-profile"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}
