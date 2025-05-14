resource "aws_iam_role" "observability_irsa_role" {
  for_each = local.observability

  name = "${each.value.sa_name}-role"

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
            "${var.oidc_provider}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.sa_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "observability_s3_policy" {
  for_each = local.observability

  name        = "${each.value.sa_name}-s3-policy"
  description = "S3 access policy for ${each.value.sa_name}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload"
        ]
        Resource = flatten([
          each.key == "mimir" ? [
            "arn:aws:s3:::${each.value.bucket}",
            "arn:aws:s3:::${each.value.bucket}/*",
            "arn:aws:s3:::${each.value.bucket}-alertmanager",
            "arn:aws:s3:::${each.value.bucket}-alertmanager/*",
            "arn:aws:s3:::${each.value.bucket}-ruler",
            "arn:aws:s3:::${each.value.bucket}-ruler/*"
          ] : [
            "arn:aws:s3:::${each.value.bucket}",
            "arn:aws:s3:::${each.value.bucket}/*"
          ]
        ])
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "observability_attach" {
  for_each = local.observability

  role       = aws_iam_role.observability_irsa_role[each.key].name
  policy_arn = aws_iam_policy.observability_s3_policy[each.key].arn
}
