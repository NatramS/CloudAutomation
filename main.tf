provider "aws" {
  region = "us-east-1"  # Update with your desired region
}
# Define VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Attach internet gateway to VPC
resource "aws_vpc_attachment" "my_igw_attachment" {
  vpc_id       = aws_vpc.my_vpc.id
  internet_gateway_id = aws_internet_gateway.my_igw.id
}

# Define subnets (you may want to add more subnets for different Availability Zones)
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Create auto scaling group
resource "aws_autoscaling_group" "my_asg" {
  name                 = "my-asg"
  launch_configuration = aws_launch_configuration.my_lc.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier = [aws_subnet.my_subnet.id]
}

# Create launch configuration
resource "aws_launch_configuration" "my_lc" {
  name          = "my-lc"
  image_id      = "ami-12345678" # Replace with your desired AMI ID
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }

  security_groups = [aws_security_group.my_security_group.name]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup python -m SimpleHTTPServer 8080 &
              EOF
}

# Create security group
resource "aws_security_group" "my_security_group" {
  name        = "my-sg"
  description = "Allow inbound traffic on port 80"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IAM policy for restarting web server
resource "aws_iam_policy" "restart_web_server_policy" {
  name        = "restart_web_server_policy"
  description = "Allows restarting the web server"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:RebootInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create IAM user
resource "aws_iam_user" "web_server_admin" {
  name = "web-server-admin"
}

# Attach policy to IAM user
resource "aws_iam_user_policy_attachment" "restart_web_server_attachment" {
  user       = aws_iam_user.web_server_admin.name
  policy_arn = aws_iam_policy.restart_web_server_policy.arn
}

# Create load balancer
resource "aws_lb" "my_lb" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_security_group.id]
  subnets            = ["subnet-05a9b0f3911ddec7d"]

  enable_deletion_protection = false

  tags = {
    Name = "my-lb"
  }
}

# Create target group
resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
  }
}

# Create listener
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}
