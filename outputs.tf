output "rancher_server_url" {
  value = module.rancher_common.rancher_url
}

output "server_ip" {
  value = aws_instance.server.public_ip
}

output "nodes_ip" {
  value = join(", ", aws_instance.nodes.*.public_ip)
}

output "cni" {
  value = module.rancher_common.rancher_cni
}

output "rancher_admin_password" {
  value     = random_password.rancher_admin_password.result
  sensitive = true
}
