locals {
  region = "ap-northeast-2"
  account_id = "880076045111"

  ### karpenter
  karpenter = {
    sa_name   = "karpenter"
    namespace = "karpenter"
  }

  ### kube-system
/*
aws_utility = {
  sa_name = {
    ebs_csi_controller        = "ebs-csi-controller-sa"
    load_balancer_controller  = "load-balancer-controller-sa"
    external_dns              = "external-dns-sa"
  }    
  namespace = "kube-system"
}
*/
  aws_utility = {
    ebs_csi_driver = {
      namespace = "ebs-csi-driver"
      sa_name   = "ebs-csi-driver-sa"
    }
    load_balancer_controller = {
      namespace = "load-balancer-controller"
      sa_name   = "load-balancer-controller-sa"
    }
    external_dns = {
      namespace = "external-dns"
      sa_name   = "external-dns-sa"
    }
  }

  ### observability
  observability = {
    loki = {
      namespace = "loki"
      bucket    = "soundory-loki"
      sa_name   = "loki-sa"
    }
    tempo = {
      namespace = "tempo"
      bucket    = "soundory-tempo"
      sa_name   = "tempo-sa"
    }
    mimir = {
      namespace = "mimir"
      bucket    = "soundory-mimir"
      sa_name   = "mimir-sa"
    }
  }
}