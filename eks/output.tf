output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "cluster_id" {
  value = module.eks_cluster.cluster_id
}
output "kubeconfig" {
  value = module.eks_cluster.kubeconfig
}
output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}