/* 
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}
*/
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true
  cluster_encryption_config      = {}

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets


eks_managed_node_groups = {
  general = {
    name            = "platform"
    use_name_prefix = true

    subnet_ids = var.private_subnets

    min_size     = 5
    max_size     = 5
    desired_size = 5

    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.medium"]

    iam_role_additional_policies = {
      SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  service = {
    name            = "service"
    use_name_prefix = true

    subnet_ids = var.private_subnets

    min_size     = 1
    max_size     = 1
    desired_size = 1

    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.small"]

    iam_role_additional_policies = {
      SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    taints = [
      {
        key    = "node"
        value  = "service"
        effect = "NO_SCHEDULE"
      }
    ]
    labels = {
      node-role = "service"
    }
  }
}

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::880076045111:user/kimdongju"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

/*
resource "helm_release" "aws-utility" {
  name       = "aws-utility"
  chart      = "../aws-utility-helm-chart"
  namespace  = "kube-system"
  depends_on = [module.eks]
}
*/