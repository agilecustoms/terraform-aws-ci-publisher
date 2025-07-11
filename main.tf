data "aws_iam_policy_document" "publisher_codeartifact" {
  statement {
    effect = "Allow"
    actions = [
      "codeartifact:GetAuthorizationToken",
    ]
    resources = [
      "arn:${var.partition}:codeartifact:${var.region}:${var.account_id}:domain/${var.codeartifact_domain_name}",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codeartifact:GetRepositoryEndpoint",
      "codeartifact:ReadFromRepository",
    ]
    resources = [
      "arn:${var.partition}:codeartifact:${var.region}:${var.account_id}:repository/${var.codeartifact_domain_name}/*"
    ]
  }

  statement {
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

  statement {
    effect = "Allow"
    actions = [
      "sts:GetServiceBearerToken",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = ["codeartifact.amazonaws.com"]
      variable = "sts:AWSServiceName"
    }
  }
}

data "aws_iam_policy_document" "publisher_ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = ["arn:${var.partition}:ecr:${var.region}:${var.account_id}:repository/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.allow_delete ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ecr:BatchDeleteImage", # to override tags such as "latest"
      ]
      resources = ["arn:${var.partition}:ecr:${var.region}:${var.account_id}:repository/*"]
    }
  }
}

data "aws_iam_policy_document" "publisher_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:${var.partition}:s3:::${var.s3_bucket_name}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = ["arn:${var.partition}:s3:::${var.s3_bucket_name}${var.s3_prefix}/*"]
  }

  dynamic "statement" {
    for_each = var.allow_delete ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "s3:DeleteObject",
      ]
      resources = ["arn:${var.partition}:s3:::${var.s3_bucket_name}${var.s3_prefix}/*"]
    }
  }
}

data "aws_iam_policy_document" "publisher" {
  source_policy_documents = concat(
    var.codeartifact_domain_name == "" ? [] : [data.aws_iam_policy_document.publisher_codeartifact.json],
    [
      data.aws_iam_policy_document.publisher_ecr.json,
      data.aws_iam_policy_document.publisher_s3.json,
    ]
  )
}

resource "aws_iam_policy" "publisher" {
  path   = var.iam_policy_path
  name   = var.iam_policy_name
  policy = data.aws_iam_policy_document.publisher.json
}
