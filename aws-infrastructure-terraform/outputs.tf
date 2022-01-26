output "jenkins-dns" {
  value = module.jenkins-master.jenkins-dns
}

output "webhook" {
  value = module.lambda-api-gateway.webhook
}