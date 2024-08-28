resource "aws_vpc" "custome_vpc" {
cidr_block = "10.0.0.0/16"
tags ={
    name = "custom_vpc"
}
}
resource "aws_internet_gateway" "custom_internet" {
    vpc_id = aws_vpc.custome_vpc.id
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.custome_vpc.id
    cidr_block = "10.0.128.0/18"
    availability_zone = "ap-south-1a"
    tags = {
      name ="public"
    }
}

resource "aws_subnet" "public2" {
    vpc_id = aws_vpc.custome_vpc.id
    availability_zone = "ap-south-1b"
    cidr_block = "10.0.192.0/18"
    tags ={
        name ="public2"
    }
  
}
resource "aws_route_table" "public_route" {
    vpc_id = aws_vpc.custome_vpc.id
    route  {
       gateway_id = aws_internet_gateway.custom_internet.id
        cidr_block ="0.0.0.0/0"
  }
}


resource "aws_route_table_association" "public_association" {
    subnet_id = aws_subnet.public.id

    route_table_id = aws_route_table.public_route.id
  
}
resource "aws_route_table_association" "dev" {

    subnet_id = aws_subnet.public2.id
    route_table_id = aws_route_table.public_route.id
  
}


resource "aws_subnet" "private" {
    vpc_id = aws_vpc.custome_vpc.id
    cidr_block = "10.0.0.0/17"

    tags = {
      name ="private"
    }
}


resource "aws_eip" "elastic_natgatway" {
    domain ="vpc"
  
}
resource "aws_nat_gateway" "custome_natgatway"{
    allocation_id = aws_eip.elastic_natgatway.id
    subnet_id = aws_subnet.public.id
}
resource "aws_route_table" "private" {
vpc_id = aws_vpc.custome_vpc.id
tags ={
    name ="private-route"
}
route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.custome_natgatway.id

}


  
}
resource "aws_route_table_association" "private" {
    route_table_id = aws_route_table.private.id
    subnet_id = aws_subnet.private.id
  
}
resource "aws_lb_target_group" "test" {
    name = "backend-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.custome_vpc.id
}
resource "aws_lb" "backend_loadblancer" {
    name ="loadblancer"
    internal = false
    load_balancer_type = "application"
    subnets = [ aws_subnet.public.id,aws_subnet.public2.id ]
    depends_on = [ aws_lb_target_group.test ]
    security_groups = [aws_security_group.instance.id]
  
}
resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.custome_vpc.id
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

