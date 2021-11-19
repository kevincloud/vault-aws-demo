resource "aws_vpc" "main-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags = {
        Name = "vault-aws-vpc-${var.prefix}"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main-vpc.id

    tags = {
        Name = "vault-aws-igw-${var.prefix}"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_subnet" "public-subnet" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.0.10.0/24"
    map_public_ip_on_launch = true
    availability_zone = "${var.aws_region}a"
    depends_on = [aws_internet_gateway.igw]

    tags = {
        Name = "vault-aws-public-${var.prefix}"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_subnet" "public-subnet-2" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.0.11.0/24"
    map_public_ip_on_launch = true
    availability_zone = "${var.aws_region}b"
    depends_on = [aws_internet_gateway.igw]

    tags = {
        Name = "vault-aws-public-${var.prefix}"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

# resource "aws_subnet" "private-subnet" {
#     count = 2
#     vpc_id = aws_vpc.main-vpc.id
#     cidr_block = "10.0..0/24"
#     availability_zone = element(var.aws_azs, count.index)

#     tags = {
#         Name = "jp-k8s-private-subnet-${count.index}-${var.prefix}"
#         "kubernetes.io/cluster/javaperks" = "owned"
#         owner = var.owner
#         se-region = var.se_region
#         purpose = var.purpose
#         ttl = var.ttl
#         terraform = var.terraform
#     }
# }

resource "aws_route" "public-routes" {
    route_table_id = aws_vpc.main-vpc.default_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

resource "aws_eip" "nat-ip" {
    vpc = true

    tags = {
        Name = "vault-aws-eip-${var.prefix}"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_nat_gateway" "natgw" {
    allocation_id   = aws_eip.nat-ip.id
    subnet_id       = aws_subnet.public-subnet.id
    depends_on      = [aws_internet_gateway.igw, aws_subnet.public-subnet]

    tags = {
        Name = "jp-k8s-natgw-${var.prefix}"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_route_table" "natgw-route" {
    vpc_id = aws_vpc.main-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.natgw.id
    }

    tags = {
        Name = "vault-aws-natgw-route-${var.prefix}"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_route_table" "igw-route" {
    vpc_id = aws_vpc.main-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "vault-aws-igw-route-${var.prefix}"
        owner = var.owner
        se-region = var.se_region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_route_table_association" "route-out" {
    route_table_id = aws_route_table.igw-route.id
    subnet_id      = aws_subnet.public-subnet.id
}

resource "aws_db_subnet_group" "vault-db-subnet" {
    name       = "${var.prefix}-vault-db-subnet"
    subnet_ids = [aws_subnet.public-subnet.id, aws_subnet.public-subnet-2.id]

    tags = {
        Name = "Vault DB subnet group"
            owner = var.owner
            se-region = var.se_region
            purpose = var.purpose
            ttl = var.ttl
            terraform = var.terraform
    }
}
