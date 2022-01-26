output "instance_id" {
  value = aws_instance.jenkins-master.id
}

output "master_instance" {
  value = aws_instance.jenkins-master
}

output "master_sg_id" {
  value = aws_security_group.jenkins-master.id
}

output "elb-dns" {
  value = aws_elb.jenkins_elb.dns_name
}

output "elb-id" {
  value = aws_elb.jenkins_elb.id
}

output "jenkins-dns" {
  value = "https://${aws_route53_record.jenkins_master.name}."
}

output "master-private-ip" {
  value = aws_instance.jenkins-master.private_ip
}
