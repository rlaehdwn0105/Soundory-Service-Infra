module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = var.vpc_name
  cidr   = var.vpc_cidr

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = [for i in range(0, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i in range(0, 2) : cidrsubnet(var.vpc_cidr, 8, i + 100)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

