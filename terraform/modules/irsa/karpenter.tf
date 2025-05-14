resource "aws_iam_role" "karpenter_controller_irsa" {
  name = "${local.karpenter.sa_name}-controller-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:aud" : "sts.amazonaws.com",
            "${var.oidc_provider}:sub" : "system:serviceaccount:${local.karpenter.namespace}:${local.karpenter.sa_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "karpenter-controller-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Karpenter",
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ],
        Resource = ["*"]
      },
      {
        Sid    = "ConditionalEC2Termination",
        Effect = "Allow",
        Action = ["ec2:TerminateInstances"],
        Resource = ["*"],
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid    = "PassNodeIAMRole",
        Effect = "Allow",
        Action = ["iam:PassRole"],
        Resource = [
          "arn:aws:iam::${local.account_id}:role/${var.node_role_name}"
        ]
      },
      {
        Sid    = "EKSClusterEndpointLookup",
        Effect = "Allow",
        Action = ["eks:DescribeCluster"],
        Resource = [
          "arn:aws:eks:${local.region}:${local.account_id}:cluster/${var.eks_cluster_name}"
        ]
      },
      {
        Sid    = "AllowScopedInstanceProfileCreationActions",
        Effect = "Allow",
        Action = ["iam:CreateInstanceProfile"],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.eks_cluster_name}" = "owned",
          },
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileTagActions",
        Effect = "Allow",
        Action = ["iam:TagInstanceProfile"],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.eks_cluster_name}"  = "owned",
            "aws:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}" = "owned",
          },
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"     = "*",
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"    = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileActions",
        Effect = "Allow",
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}" = "owned",
          },
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid    = "AllowInstanceProfileReadActions",
        Effect = "Allow",
        Action = ["iam:GetInstanceProfile"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller_irsa.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}

### karpenter_node_role
resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole-${var.eks_cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "Name" = "KarpenterNodeRole-${var.eks_cluster_name}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
    "karpenter.sh/discovery" = var.eks_cluster_name
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
