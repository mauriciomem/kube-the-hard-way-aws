output "cluster_instance_ids" {
  value = { for k in module.ec2_k8s_cluster : k.tags_all.Name => k.id }
}

output "client_instance_id" {
  value = { for k in module.ec2_client : k.tags_all.Name => k.id }
}