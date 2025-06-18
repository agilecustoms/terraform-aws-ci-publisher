data "aws_iam_policy_document" "publisher" {

  dynamic "statement" {
    for_each = var.codeartifact_domain_name != "" ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "codeartifact:PublishPackageVersion",
        "codeartifact:PutPackageMetadata"
      ]
      # arn:${Partition}:codeartifact:${Region}:${Account}:package/${DomainName}/${RepositoryName}/${PackageFormat}/${PackageNamespace}/${PackageName}
      # ${PackageNamespace} for maven is a <dependency> groupId
      # ${PackageNamespace} for npm is a scope like '@types' in '@types/node`
      resources = [
        "arn:${var.partition}:codeartifact:${var.region}:${var.account_id}:package/${var.codeartifact_domain_name}/*",
      ]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.allow_override ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ecr:BatchDeleteImage", # to override tags such as "latest"
      ]
      resources = ["*"]
    }
  }

  # S3

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = ["arn:${var.partition}:s3:::${var.s3_bucket_name}${var.s3_prefix}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
    ]
    resources = ["arn:${var.partition}:s3:::${var.s3_bucket_name}${var.s3_prefix}/*/latest/*"]
  }

  dynamic "statement" {
    for_each = var.allow_override ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:DeleteObject",
      ]
      resources = ["arn:${var.partition}:s3:::${var.s3_bucket_name}${var.s3_prefix}/*"]
    }
  }
}

resource "aws_iam_policy" "publisher" {
  path   = var.iam_path
  name   = var.iam_role_name
  policy = data.aws_iam_policy_document.publisher.json
}
