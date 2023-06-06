# VPC
resource "aws_vpc" "dev" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = (merge(local.default_tags,
    {
      "Name" = "${local.sig}-vpc",
    }
  ))
}

# Internet Gateway
resource "aws_internet_gateway" "dev" {
  vpc_id     = aws_vpc.dev.id
  depends_on = [aws_vpc.dev]
  tags = (merge(local.default_tags,
    {
      "Name" = "${local.sig}-igw"
    }
  ))
}

# Subnet
resource "aws_subnet" "dev-public-a" {
  vpc_id                  = aws_vpc.dev.id
  cidr_block              = "10.0.0.0/23"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  depends_on              = [aws_vpc.dev]
  tags = (merge(local.default_tags,
    {
      "Name"                   = "${local.sig}-public-a"
      "kubernetes.io/role/elb" = 1
    }
  ))
}

resource "aws_subnet" "dev-public-c" {
  vpc_id                  = aws_vpc.dev.id
  availability_zone       = "ap-northeast-1c"
  cidr_block              = "10.0.2.0/23"
  map_public_ip_on_launch = true
  depends_on              = [aws_vpc.dev]
  tags = (merge(local.default_tags,
    {
      "Name"                   = "${local.sig}-public-c"
      "kubernetes.io/role/elb" = 1
    }
  ))
}

resource "aws_subnet" "dev-private-a" {
  vpc_id                  = aws_vpc.dev.id
  availability_zone       = "ap-northeast-1a"
  cidr_block              = "10.0.128.0/22"
  map_public_ip_on_launch = false
  depends_on              = [aws_vpc.dev]
  tags = (merge(local.default_tags,
    {
      "Name"                               = "${local.sig}-private-a",
      "kubernetes.io/cluster/${local.sig}" = "shared"
    }
  ))
}

resource "aws_subnet" "dev-private-c" {
  vpc_id                  = aws_vpc.dev.id
  availability_zone       = "ap-northeast-1c"
  cidr_block              = "10.0.132.0/22"
  map_public_ip_on_launch = false
  depends_on              = [aws_vpc.dev]
  tags = (merge(local.default_tags,
    {
      "Name"                               = "${local.sig}-private-c"
      "kubernetes.io/cluster/${local.sig}" = "shared"
    }
  ))
}

# EIP
resource "aws_eip" "dev-nat-gateway-a" {
  vpc        = true
  depends_on = [aws_internet_gateway.dev]
  tags = (merge(local.default_tags,
    {
      Name = "${local.sig}-nat-gw-eip-a"
    }
  ))
}

# resource "aws_eip" "dev-nat-gateway-c" {
#   vpc        = true
#   depends_on = [aws_internet_gateway.dev]
#   tags = (merge(local.default_tags,
#     {
#       Name = "${local.sig}-nat-gw-eip-c"
#     }
#   ))
# }


# NAT Gateway
resource "aws_nat_gateway" "dev-a" {
  allocation_id = aws_eip.dev-nat-gateway-a.id
  subnet_id     = aws_subnet.dev-public-a.id
  depends_on = [
    aws_eip.dev-nat-gateway-a,
    aws_subnet.dev-public-a,
    aws_internet_gateway.dev
  ]
  tags = (merge(local.default_tags,
    {
      Name = "${local.sig}-nat-gw-a"
    }
  ))
}

# MEMO: In the development environment, a single NAT Gateway is utilized to restrict excessive resource consumption.
# resource "aws_nat_gateway" "dev-c" {
#   allocation_id = aws_eip.dev-nat-gateway-c.id
#   subnet_id     = aws_subnet.dev-public-c.id
#   depends_on = [
#     aws_eip.dev-nat-gateway-c,
#     aws_subnet.dev-public-c,
#     aws_internet_gateway.dev
#   ]
#   tags = (merge(local.default_tags,
#     {
#       Name = "${local.sig}-nat-gw-c"
#     }
#   ))
# }

# Route Table
resource "aws_route_table" "dev-public-a" {
  vpc_id = aws_vpc.dev.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev.id
  }
  depends_on = [aws_internet_gateway.dev]
  tags = (merge(local.default_tags,
    {
      "Name" = "${local.sig}-public-a"
    }
  ))
}

resource "aws_route_table" "dev-public-c" {
  vpc_id = aws_vpc.dev.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev.id
  }
  depends_on = [aws_internet_gateway.dev]
  tags = {
    Name = "${local.sig}-public-c"
  }
}

resource "aws_route_table" "dev-private-a" {
  vpc_id = aws_vpc.dev.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dev-a.id
  }
  depends_on = [aws_nat_gateway.dev-a]
  tags = (merge(local.default_tags,
    {
      "Name" = "${local.sig}-private-a"
    }
  ))
}

resource "aws_route_table" "dev-private-c" {
  vpc_id = aws_vpc.dev.id
  route {
    cidr_block     = "0.0.0.0/0"
    # nat_gateway_id = aws_nat_gateway.dev-c.id
    nat_gateway_id = aws_nat_gateway.dev-a.id
  }
  # depends_on = [aws_nat_gateway.dev-c]
  depends_on = [aws_nat_gateway.dev-a]

  tags = (merge(local.default_tags,
    {
      "Name" = "${local.sig}-private-c"
    }
  ))
}

# Route Table Association
resource "aws_route_table_association" "dev-public-a" {
  subnet_id      = aws_subnet.dev-public-a.id
  route_table_id = aws_route_table.dev-public-a.id
  depends_on     = [aws_route_table.dev-public-a]
}

resource "aws_route_table_association" "dev-public-c" {
  subnet_id      = aws_subnet.dev-public-c.id
  route_table_id = aws_route_table.dev-public-c.id
  depends_on     = [aws_route_table.dev-public-c]
}

resource "aws_route_table_association" "dev-private-a" {
  subnet_id      = aws_subnet.dev-private-a.id
  route_table_id = aws_route_table.dev-private-a.id
  depends_on     = [aws_route_table.dev-private-a]
}

resource "aws_route_table_association" "dev-private-c" {
  subnet_id      = aws_subnet.dev-private-c.id
  route_table_id = aws_route_table.dev-private-c.id
  depends_on     = [aws_route_table.dev-private-c]
}
