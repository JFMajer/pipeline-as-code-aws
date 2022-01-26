data "aws_ami" "jenkins-master" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["jenkins-master-*"]
  }
}

resource "aws_instance" "jenkins-master" {
  ami                    = data.aws_ami.jenkins-master.id
  instance_type          = var.instance_type
  key_name               = var.key
  vpc_security_group_ids = [aws_security_group.jenkins-master.id]
  subnet_id              = element(var.subnets, 0)

  root_block_device {
    volume_type = "gp2"
    volume_size = 30
  }

  tags = {
    Name = "${var.name_prefix}-jenkins-master"
  }
}

resource "aws_security_group" "jenkins-master" {
  name        = "jenkins-master"
  description = "Jenkins master server"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.elb_jenkins_sg.id]
    cidr_blocks     = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-master_sg-${var.vpc_name}"
  }
}

resource "aws_elb" "jenkins_elb" {
  subnets                   = [for s in var.public_subnets : s]
  cross_zone_load_balancing = true
  instances                 = [aws_instance.jenkins-master.id]
  security_groups           = [aws_security_group.elb_jenkins_sg.id]

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.ssl_arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    target              = "TCP:8080"
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "jenkins-master-elb-${var.vpc_name}"
  }
}

resource "aws_security_group" "elb_jenkins_sg" {
  name        = "elb_jenkins_sg"
  description = "Jenkins ELB security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_elb_sg-${var.vpc_name}"
  }
}

resource "aws_route53_record" "jenkins_master" {
  zone_id = var.hosted_zone_id
  name    = "jenkins.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_elb.jenkins_elb.dns_name
    zone_id                = aws_elb.jenkins_elb.zone_id
    evaluate_target_health = true
  }
}