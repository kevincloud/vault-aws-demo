resource "aws_instance" "jenkins-server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.jenkins_inst_type
    key_name = var.key_pair
    iam_instance_profile = aws_iam_instance_profile.jenkins-main-profile.id
    vpc_security_group_ids = [module.jenkinssg.id]
    subnet_id = aws_subnet.public-subnet.id
    private_ip = "10.0.10.201"
    user_data = templatefile("${path.module}/scripts/jenkins_install.sh", {
        AWS_REGION = var.aws_region,
        ASSET_BUCKET = var.jenkins_bucket,
        TF_ORGNAME = var.tf_org_name,
        TF_WORKSPACE = var.tf_workspace_name
    })

    tags = {
        Name = "${var.prefix}-jenkins-demo"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

data "aws_iam_policy_document" "jenkins-assume-role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "jenkins-main-access-doc" {
  statement {
    sid       = "FullAccess"
    effect    = "Allow"
    resources = ["*"]

    actions = [
        "ec2:*",
        "ec2messages:GetMessages",
        "ssm:UpdateInstanceInformation",
        "ssm:ListInstanceAssociations",
        "ssm:ListAssociations",
        "s3:*"
    ]
  }
}

resource "aws_iam_role" "jenkins-main-access-role" {
  name               = "jenkins-access-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins-assume-role.json

    tags = {
        Name = "${var.prefix}-jenkins-iam-role"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_iam_role_policy" "jenkins-main-access-policy" {
  name   = "jenkins-access-policy"
  role   = aws_iam_role.jenkins-main-access-role.id
  policy = data.aws_iam_policy_document.jenkins-main-access-doc.json
}

resource "aws_iam_instance_profile" "jenkins-main-profile" {
  name = "jenkins-access-profile"
  role = aws_iam_role.jenkins-main-access-role.name

    tags = {
        Name = "${var.prefix}-jenkins-instance-profile"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}
