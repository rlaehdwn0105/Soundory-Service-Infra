output "oidc_provider" {
  value = module.eks.oidc_provider
}
output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
output "cluster_name" {
  value = module.eks.cluster_name
}
output "node_iam_role_name" {
  value = module.eks.eks_managed_node_groups["service"].iam_role_name
}