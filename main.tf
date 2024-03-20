provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"  # Update with your desired CIDR
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Create Route Table
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Create Security Group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

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

# Launch Configuration and Auto Scaling Group
resource "aws_launch_configuration" "web_lc" {
  image_id          = "ami-0c55b159cbfafe1f0"  # Update with your desired AMI
  instance_type     = "t2.micro"               # Update with your desired instance type
  security_groups   = [sg-02d61e9f30cc43b3d]

  # Provisioner to install web server
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apache2"
      # You can add more commands here if needed
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.web_lc.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = ["10.0.0.0/24"]  # Update with your desired subnet(s)

  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
}

# Create Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = ["10.0.1.0/24"]  # Update with your desired subnet(s)
}

# Create Target Group
resource "aws_lb_target_group" "web_target_group" {
  name     = "web-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Create Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target_group.arn
  }
}

# Create IAM User with permission to restart web server
resource "aws_iam_user" "webserver_user" {
  name = "webserver-user"
}

resource "aws_iam_policy" "webserver_policy" {
  name        = "webserver-policy"
  description = "Policy to restart web server"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ec2:RebootInstances",
        Resource = "*",
      },
    ],
  })
}

resource "aws_iam_policy_attachment" "webserver_policy_attachment" {
  name       = "webserver-policy-attachment"
  users      = [aws_iam_user.webserver_user.name]
  policy_arn = aws_iam_policy.webserver_policy.arn
}
