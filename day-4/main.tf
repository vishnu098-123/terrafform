resource "aws_vpc" "custom" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "custom"

  }

}
resource "aws_internet_gateway" "internet" {
  vpc_id = aws_vpc.custom.id
  tags = {
    Name = "internet"
  }

}
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.custom.id
  cidr_block = "10.0.0.0/17"

  tags = {
    Name = "public subnet"
  }

}
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.custom.id
  cidr_block = "10.0.128.0/17"

  tags = {
    Name = "private_subnet"
  }

}
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.custom.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet.id


  }

}
resource "aws_route_table_association" "route_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route.id

}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.custom.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.private_natgateway.id
  }

}
resource "aws_route_table_association" "natgateway_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id



}
resource "aws_eip" "elastic_ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "private_natgateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public.id


}


resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.custom.id
  name   = "allow all traffic"
  tags = {
    Name = "instance"

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}
resource "aws_instance" "test" {
  ami                         = "ami-02b49a24cfb95941c"
  instance_type               = "t3.micro"
  key_name                    = "serverkey1"
  subnet_id                   = aws_subnet.public.id
  availability_zone =            "ap-south-1c"
  vpc_security_group_ids      = [aws_security_group.instance.id]
  associate_public_ip_address = true

  tags = {
    Name = "PublicInstance"
  }
}
