data "aws_iam_policy_document" "publisher_dev_ecr" {
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
}

data "aws_iam_policy_document" "publisher_dev_s3" {
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
      "s3:PutObjectTagging"
    ]
    resources = ["arn:${var.partition}:s3:::${var.s3_bucket_name}/${var.s3_dev_prefix}*"]
    condition {
      test     = "StringEquals"
      variable = "s3:RequestObjectTag/Release"
      values   = ["false"]
    }
  }

  statement {
    effect = "Deny"
    actions = [
      "s3:PutObjectTagging"
    ]
    resources = ["arn:${var.partition}:s3:::${var.s3_bucket_name}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/Release"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy_document" "publisher_dev" {
  source_policy_documents = [
    data.aws_iam_policy_document.publisher_dev_ecr.json,
    data.aws_iam_policy_document.publisher_dev_s3.json,
  ]
}
