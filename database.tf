resource "aws_db_instance" "vault-mysql" {
    allocated_storage = 10
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.t3.micro"
    identifier = var.mysql_dbname
    name = var.mysql_dbname
    vpc_security_group_ids = [aws_security_group.vault-mysql-sg.id]
    username = var.mysql_user
    password = var.mysql_pass
    skip_final_snapshot = true
}

resource "aws_security_group" "vault-mysql-sg" {
    name = "vault-mysql-sg"
    description = "mysql security group"
    vpc_id = data.aws_vpc.primary-vpc.id

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
}
