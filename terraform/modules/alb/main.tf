# ALB Module - main.tf

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false  # Set to true for production

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-${var.environment}-alb"
    }
  )
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.app_name}-${var.environment}-tg"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-${var.environment}-tg"
    }
  )
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "main" {
  count = length(var.target_ids)

  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.target_ids[count.index]
  port             = var.target_port
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  # Optional: Redirect to HTTPS in production
  # default_action {
  #   type = "redirect"
  #   redirect {
  #     port        = "443"
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-${var.environment}-http-listener"
    }
  )
}

# HTTPS Listener (uncomment and configure for production)
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.main.arn
#   }
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.app_name}-${var.environment}-https-listener"
#     }
#   )
# }