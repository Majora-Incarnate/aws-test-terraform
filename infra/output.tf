output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "es_subnet_ids" {
  value = module.vpc.elasticache_subnets
}

output "eks_subnet_ids" {
  value = module.vpc.private_subnets
}