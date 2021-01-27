resource "aws_instance" "vault-ec2-deny" {
    ami = data.aws_ami.ubuntu2.id
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.vault-ec2-sg.id]
    user_data = templatefile("${path.module}/scripts/ec2_install.sh", {
        VAULT_IP = aws_instance.vault-server[0].public_ip
        AWS_ACCESS_KEY = var.aws_access_key
        AWS_SECRET_KEY = var.aws_secret_key
        AWS_SESSION_TOKEN = var.aws_session_token
        AWS_REGION = var.aws_region
    })

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
    user_data = templatefile("${path.module}/scripts/ec2_install.sh", {
        VAULT_IP = aws_instance.vault-server[0].public_ip
        AWS_ACCESS_KEY = var.aws_access_key
        AWS_SECRET_KEY = var.aws_secret_key
        AWS_SESSION_TOKEN = var.aws_session_token
        AWS_REGION = var.aws_region
    })
    
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
