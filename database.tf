resource "aws_db_instance" "vault-mysql" {
    allocated_storage = 10
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.${var.instance_type}"
    identifier = "${var.prefix}${var.mysql_dbname}"
    name = "${var.prefix}${var.mysql_dbname}"
    vpc_security_group_ids = [aws_security_group.vault-mysql-sg.id]
    db_subnet_group_name = "${var.prefix}-vault-db-subnet"
    username = var.mysql_user
    password = var.mysql_pass
    skip_final_snapshot = true
    
    tags = {
        Name = "${var.prefix}-vault-mysql"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_db_subnet_group" "vault-db-subnet" {
    name       = "${var.prefix}-vault-db-subnet"
    subnet_ids = [aws_subnet.public-subnet.id, aws_subnet.public-subnet-2.id]

    tags = {
        Name = "Vault DB subnet group"
            owner = var.owner
            se-region = var.se-region
            purpose = var.purpose
            ttl = var.ttl
            terraform = var.terraform
    }
}

resource "aws_security_group" "vault-mysql-sg" {
    name = "${var.prefix}-vault-mysql-sg"
    description = "mysql security group"
    vpc_id = aws_vpc.main-vpc.id

    ingress {
        from_port = 3306
        to_port = 3306
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
