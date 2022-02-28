# Outputs

output "rancher_url" {
  value = "https://${var.rancher_server_dns}"
}

output "custom_cluster_command" {
  value       = rancher2_cluster.quickstart_workload.cluster_registration_token.0.node_command
  description = "Docker command used to add a node to the quickstart cluster"
}

output "rancher_cni" {
  value       = local.rke_network_plugin
  description = "CNI used by the cluster"
}

output "custom_cluster_windows_command" {
  value       = rancher2_cluster.quickstart_workload.cluster_registration_token.0.windows_node_command
  description = "Docker command used to add a windows node to the quickstart cluster"
}
