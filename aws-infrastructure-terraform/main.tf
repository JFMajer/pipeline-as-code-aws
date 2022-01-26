locals {
  vpc_name = "${var.name_prefix}_vpc"
}

resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = local.vpc_name
  }
}

resource "aws_subnet" "public_subnets" {
  vpc_id            = aws_vpc.jenkins_vpc.id
  cidr_block        = "10.0.${count.index * 2 + 1}.0/24"
  availability_zone = element(var.availability_zones, count.index)

  count = var.public_subnets_count

  tags = {
    Name = "public_10.0.${count.index * 2 + 1}.0_${element(var.availability_zones, count.index)}"
  }
}

resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.jenkins_vpc.id
  cidr_block        = "10.0.${count.index * 2}.0/24"
  availability_zone = element(var.availability_zones, count.index)

  count = var.private_subnets_count

  tags = {
    Name = "private_10.0.${count.index * 2}.0_${element(var.availability_zones, count.index)}"
  }
}

resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "igw_${local.vpc_name}"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }

  tags = {
    Name = "public_rt_${local.vpc_name}"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  count          = var.public_subnets_count
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "eip_nat_${local.vpc_name}"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(aws_subnet.public_subnets.*.id, 0)

  tags = {
    Name = "nat_${local.vpc_name}"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private_rt_${local.vpc_name}"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  count          = var.private_subnets_count
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private_rt.id
}

module "bastion" {
  source        = "./bastion"
  name_prefix   = var.name_prefix
  instance_type = var.bastion_instance_type
  subnets       = aws_subnet.public_subnets.*.id
  vpc_id        = aws_vpc.jenkins_vpc.id
  vpc_name      = local.vpc_name
  sg_name       = var.bastion_sg_name
  allowed_cidr  = var.bastion_allowed_cidr
  key           = aws_key_pair.jenkins_key.id
}

module "jenkins-master" {
  source         = "./jenkins-master"
  name_prefix    = var.name_prefix
  instance_type  = var.jenkins-master_instance_type
  subnets        = aws_subnet.private_subnets.*.id
  public_subnets = aws_subnet.public_subnets.*.id
  vpc_id         = aws_vpc.jenkins_vpc.id
  vpc_name       = local.vpc_name
  vpc_cidr       = var.vpc_cidr
  sg_name        = var.jenkins-master_sg_name
  bastion_sg_id  = module.bastion.bastion_sg_id
  allowed_cidr   = var.master_allowed_cidr
  key            = aws_key_pair.jenkins_key.id
  ssl_arn        = var.ssl_arn
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
}

module "jenkins-workers" {
  source            = "./jenkins-workers"
  name_prefix       = var.name_prefix
  subnets           = aws_subnet.private_subnets.*.id
  vpc_id            = aws_vpc.jenkins_vpc.id
  bastion_sg_id     = module.bastion.bastion_sg_id
  master_sg_id      = module.jenkins-master.master_sg_id
  key_name          = aws_key_pair.jenkins_key.id
  instance_type     = var.worker_instance_type
  master_private_ip = module.jenkins-master.master-private-ip
  master_instance   = module.jenkins-master.master_instance
  elb_id            = module.jenkins-master.elb-id
  user_data_path    = "${path.root}/join-cluster.tpl"
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}