resource "aws_iam_role" "ebs_csi_driver_sa_role" {
  name = "${local.aws_utility.ebs_csi_driver.sa_name}-role"

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
            "${var.oidc_provider}:aud" = "sts.amazonaws.com",
            "${var.oidc_provider}:sub" = "system:serviceaccount:${local.aws_utility.ebs_csi_driver.namespace}:${local.aws_utility.ebs_csi_driver.sa_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_sa_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_sa_role.name
}
