data "aws_ami" "bastion_ami" {
  most_recent = true

  owners = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.*.0-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.bastion_ami.id
  instance_type               = var.instance_type
  key_name                    = var.key
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  subnet_id                   = element(var.subnets, 0)
  associate_public_ip_address = true

  tags = {
    Name = "${var.name_prefix}-bastion"
  }
}

resource "aws_security_group" "bastion_sg" {
  name   = var.sg_name
  vpc_id = var.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "bastion_sg-${var.vpc_name}"
  }
}