resource "aws_instance" "vault-ec2-deny" {
    ami = data.aws_ami.ubuntu2.id
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.vault-ec2-sg.id]
    user_data = templatefile("${path.module}/scripts/ec2_install.sh", {
        VAULT_IP = aws_instance.vault-server.public_ip
    })

    tags = {
        Name = "${var.prefix}-vault-ec2-deny"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}

resource "aws_instance" "vault-ec2-allow" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.vault-ec2-sg.id]
    user_data = templatefile("${path.module}/scripts/ec2_install.sh", {
        VAULT_IP = aws_instance.vault-server.public_ip
    })
    
    tags = {
        Name = "${var.prefix}-vault-ec2-allow"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}

resource "aws_security_group" "vault-ec2-sg" {
    name = "${var.prefix}-vault-ec2-sg"
    description = "ec2-vault security group"
    vpc_id = data.aws_vpc.primary-vpc.id

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
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}
