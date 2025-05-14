resource "aws_iam_role" "external_dns_sa_role" {
  name = "${local.aws_utility.external_dns.sa_name}-role"

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
            "${var.oidc_provider}:sub" = "system:serviceaccount:${local.aws_utility.external_dns.namespace}:${local.aws_utility.external_dns.sa_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_sa_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = aws_iam_role.external_dns_sa_role.name
}
