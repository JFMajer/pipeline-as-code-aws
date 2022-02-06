data "aws_ami" "jenkins-worker" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["jenkins-worker-*"]
  }
}

resource "aws_launch_template" "jenkins_workers_lt" {
  name_prefix   = "jenkins-worker-lt-"
  image_id      = data.aws_ami.jenkins-worker.id
  instance_type = var.instance_type
  key_name      = var.key_name

  lifecycle {
    create_before_destroy = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 50
      volume_type = "gp2"
    }
  }

  instance_market_options {
    market_type = "spot"
  }

  vpc_security_group_ids = [aws_security_group.jenkins_workers.id]
  user_data              = base64encode("${data.template_file.user_data_jenkins_worker.rendered}")
}

resource "aws_security_group" "jenkins_workers" {
  name   = "jenkins-workers-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.master_sg_id, var.bastion_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-workers-sg"
  }
}



data "template_file" "user_data_jenkins_worker" {
  template = file(var.user_data_path)

  vars = {
    jenkins_url            = "http://${var.master_private_ip}:8080"
    jenkins_username       = "USERNAME"
    jenkins_password       = "PASSWORD"
    jenkins_credentials_id = "jenkins-slaves"
  }
}

resource "aws_autoscaling_group" "jenkins_workers" {
  name = "jenkins-workers-asg"
  launch_template {
    id      = aws_launch_template.jenkins_workers_lt.id
    version = "$Latest"
  }
  min_size = 2
  max_size = 5
  depends_on = [
    var.master_instance,
    var.elb_id
  ]
  vpc_zone_identifier = [for s in var.subnets : s]
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "jenkins-workers"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_metric_alarm" "high-cpu-jenkins-workers-alarm" {
  alarm_name          = "high-cpu-jenkins-workers-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.jenkins_workers.name
  }
  alarm_description = "To monitors workers CPU Utilization"
  alarm_actions     = [aws_autoscaling_policy.scale-out.arn]
}

resource "aws_autoscaling_policy" "scale-out" {
  name                   = "scale-out-jenkins-workers"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  autoscaling_group_name = aws_autoscaling_group.jenkins_workers.name
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "low-cpu-jenkins-workers-alarm" {
  alarm_name          = "low-cpu-jenkins-workers-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.jenkins_workers.name
  }
  alarm_description = "To monitors workers CPU Utilization"
  alarm_actions     = [aws_autoscaling_policy.scale-in.arn]
}

resource "aws_autoscaling_policy" "scale-in" {
  name                   = "scale-in-jenkins-workers"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  autoscaling_group_name = aws_autoscaling_group.jenkins_workers.name
  cooldown               = 300
}