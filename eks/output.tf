output "cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}
output "cluster_id" {
  value = module.eks_cluster.cluster_id
}
output "kubeconfig" {
  value = module.eks_cluster.kubeconfig
}
output "cluster_security_group_id" {
  value = module.eks_cluster.cluster_security_group_id
}

output "worker_iam_role_name" {
  value = module.eks_cluster.worker_iam_role_name
}