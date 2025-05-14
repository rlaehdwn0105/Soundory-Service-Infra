terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.97.0"
    }
    /* 
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
    */
  }
}
provider "aws" {}
module "vpc" {
  source        = "./modules/vpc"
  vpc_name      = "soundory-vpc"
  vpc_cidr      = "10.0.0.0/16"
  cluster_name  = "soundory-cluster"
}

module "eks" {
  source          = "./modules/eks"
  cluster_name    = "soundory-cluster"
  cluster_version = "1.32"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

module "irsa" {
  source             = "./modules/irsa"
  eks_cluster_name   = module.eks.cluster_name
  oidc_provider      = module.eks.oidc_provider
  oidc_provider_arn  = module.eks.oidc_provider_arn
  node_role_name     = module.eks.node_iam_role_name
}