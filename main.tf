provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "my_route_table_association_subnet1" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "my_route_table_association_subnet2" {
  subnet_id      = aws_subnet.my_subnet_01.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "my_subnet_01" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
}
# Create Security Group
resource "aws_security_group" "my_security_group" {
  vpc_id = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IAM User
resource "aws_iam_user" "web_server_user" {
  name = "web_server_user"
}

# Attach Policy to IAM User
resource "aws_iam_user_policy_attachment" "attach" {
  user       = aws_iam_user.web_server_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"  # Change this policy to the one that grants access to restart the web server
}

# Create Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_security_group.id]
  subnets            = [aws_subnet.my_subnet.id, aws_subnet.my_subnet_01.id]  # Update with your desired subnet(s) in different Availability Zones
}

# Create Auto Scaling Group
resource "aws_launch_configuration" "web_launch_config" {
  image_id = "ami-080e1f13689e07408"  # Update with your desired AMI ID
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_launch_config.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.my_subnet.id]
}

# Create Web Server Instance
resource "aws_instance" "web_server_instance" {
  ami             = "ami-080e1f13689e07408"  # Update with your desired AMI ID
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.my_subnet.id
  security_groups = [aws_security_group.my_security_group.id]

  tags = {
    Name = "web-server-instance"
  }
  provisioner "remote-exec" {
    connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host     = aws_instance.web_server_instance.public_ip
}
    inline = [
      "sudo sed -i 's/80/8080/' /etc/httpd/conf/httpd.conf",
      "sudo systemctl restart httpd"
    ]
  }
}
