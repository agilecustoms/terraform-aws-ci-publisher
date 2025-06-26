# terraform-aws-ci-publisher
IAM policy `/ci/publisher` to publish (release) artifacts in AWS: S3, ECR, CodeArtifact
This policy is designed to be used in CI pipeline last step when you already built artifacts and want to publish (upload) them.

The policy covers major types of artifact stores in AWS:
- S3 to store arbitrary binaries, policy allows `s3:PutObject` in specified S3 bucket
- ECR to store Docker images, policy allows `ecr:PutImage` in all ECR repos in the account
- CodeArtifact to store software packages, policy allows `codeartifact:PublishPackageVersion` in specified CodeArtifact domain

## Usage
```hcl
module "publisher_policy" {
  source = "git::https://github.com/agilecustoms/terraform-aws-ci-publisher.git?ref=v1"

  account_id               = local.account_id  # AWS account ID, e.g. 123456789012
  region                   = "us-east-1"
  s3_bucket_name           = "my-company-dist" # {company}-dist is a good convention
  codeartifact_domain_name = "my-company"      # if you use CodeArtifact
}
```

## How to create a role with this policy
This module creates just policy, and here is a _recommendation_ how to create a role.
For roles used in CI pipelines, it is highly recommended to use OIDC provider, not IAM user with credentials.
```hcl
variable "company" {
  type        = string
  description = "GitHub org name (typically just company name)"
}

locals {
  oidc_provider = "token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.oidc_provider}"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider}:sub"
      values   = ["repo:${var.company}/*"]
    }
  }
}

resource "aws_iam_role" "publisher" {
  path               = "/ci/"
  name               = "publisher"
  description        = "Publishing artifacts in S3, ECR and CodeArtifact"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
}

module "publisher_policy" {
  source = "git::https://github.com/agilecustoms/terraform-aws-ci-publisher.git?ref=v1"

  account_id               = local.account_id
  codeartifact_domain_name = local.artifact_domain_name
  region                   = var.region
  s3_bucket_name           = aws_s3_bucket.dist.id
}

resource "aws_iam_role_policy_attachment" "publisher" {
  role       = aws_iam_role.publisher.name
  policy_arn = module.publisher_policy.policy_arn
}
``` 
