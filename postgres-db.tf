resource "aws_db_instance" "vault-postgres" {
    allocated_storage = 10
    storage_type = "gp2"
    engine = "postgres"
    engine_version = "13.3"
    instance_class = "db.${var.db_instance_type}"
    identifier = "${var.prefix}${var.postgres_dbname}"
    name = "${var.prefix}${var.postgres_dbname}"
    vpc_security_group_ids = [aws_security_group.vault-postgres-sg.id]
    db_subnet_group_name = aws_db_subnet_group.vault-db-subnet.id
    username = var.db_user
    password = var.db_pass
    parameter_group_name   = aws_db_parameter_group.postgres-params.name
    skip_final_snapshot = true
    
    tags = {
        Name = "${var.prefix}-vault-postgres"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_db_parameter_group" "postgres-params" {
    name   = var.postgres_dbname
    family = "postgres13"

    parameter {
        name  = "log_connections"
        value = "1"
    }

    tags = {
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_security_group" "vault-postgres-sg" {
    name = "${var.prefix}-vault-postgres-sg"
    description = "postgres security group"
    vpc_id = aws_vpc.main-vpc.id

    ingress {
        from_port = 5432
        to_port = 5432
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
