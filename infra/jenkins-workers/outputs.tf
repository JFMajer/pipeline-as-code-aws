output "worker_security_group" {
  value = aws_security_group.jenkins_workers.id
}