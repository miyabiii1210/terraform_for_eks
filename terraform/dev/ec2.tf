# Key Pair
locals {
  key_name = "hoge-dev"
}

# EIP
resource "aws_eip" "eip" {
  vpc = true
  tags = merge(local.default_tags, {
    "Name" = "${local.sig}-external"
  })
}

# EC2 Instance
resource "aws_instance" "amazon-linux2-dev-external" {
  ami                         = data.aws_ami.amazon-linux2.id
  associate_public_ip_address = true
  availability_zone           = "ap-northeast-1a"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.dev-public-a.id
  key_name                    = local.key_name
  vpc_security_group_ids = [
      aws_security_group.dev-ec2-tf.id
  ]
  tags = (merge(local.default_tags,
    {
      "Name" = "${local.sig}-external"
    }
  ))
}

# Attachments for EC2 Instance
resource "aws_eip_association" "eip_association" {
  instance_id   = aws_instance.amazon-linux2-dev-external.id
  allocation_id = aws_eip.eip.id
}

# Security Group for EC2 Instance
resource "aws_security_group" "dev-ec2-tf" {
  vpc_id      = aws_vpc.dev.id
  name        = "${local.sig}-ec2-tf-sg"
  description = "for ec2 instance"
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.default_tags
}

resource "aws_security_group_rule" "dev-ec2-tf-22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dev-ec2-tf.id
}

# AMI
data "aws_ami" "amazon-linux2" {
  most_recent = true
  owners      = [ "137112412989" ]
  filter {
      name   = "name"
      values = ["amzn2-ami-kernel-5.10-hvm-2.0.*-x86_64-gp2"]
  }
  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}

data "aws_ami" "ubuntu-2004" {
  most_recent = true
  owners      = [ "099720109477" ]
  filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}