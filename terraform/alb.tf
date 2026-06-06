# ===== NETWORK LOAD BALANCER =====
resource "aws_lb" "web" {
  name               = "web-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "web-nlb"
  }
}

# ===== TARGET GROUP =====
# The group of EC2 instances the NLB sends traffic to
# Health checks run every 30 seconds — unhealthy instances stop receiving traffic
resource "aws_lb_target_group" "web" {
  name        = "web-target-group"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    protocol            = "TCP"
    port                = "traffic-port"
  }

  tags = {
    Name = "web-target-group"
  }
}

# ===== LISTENER =====
# Tells the NLB to forward port 80 traffic to the target group
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}