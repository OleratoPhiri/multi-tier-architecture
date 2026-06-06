# Automatically fetches the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
    most_recent = true
    owners =["amazon"]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter{
        name = "virtualization-type"
        values = ["hvm"]
    }
}

# ===== LAUNCH TEMPLATE =====
# Blueprint for every EC2 instance the Auto Scaling Group creates
resource "aws_launch_template" "web" {
  name_prefix   = "web-server-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  # Attach the IAM role to EC2 
  # iam_instance_profile {
  #  name = aws_iam_instance_profile.ec2_profile.name
 # }

  # Attach the EC2 security group
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # The user data script — base64 encoded as required by AWS
  user_data = base64encode(file("../scripts/user_data.sh"))

  # Use IMDSv2 for instance metadata (more secure)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-server"
    }
  }
}

# ===== AUTO SCALING GROUP =====
resource "aws_autoscaling_group" "web" {
  name                = "web-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  target_group_arns   = [aws_lb_target_group.web.arn]
  vpc_zone_identifier = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Health check — replace unhealthy instances automatically
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "web-server"
    propagate_at_launch = true
  }
}

# ===== AUTO SCALING POLICY =====
# Scale up when average CPU across all instances exceeds 70%
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

