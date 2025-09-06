[![Terraform Registry](https://img.shields.io/badge/Terraform-Module-blue.svg)](https://registry.terraform.io/modules/agilecustoms/ci-publisher/aws/latest)
[![License](https://img.shields.io/github/license/agilecustoms/terraform-aws-ci-publisher)](https://github.com/agilecustoms/terraform-aws-ci-publisher/blob/main/LICENSE)

# terraform-aws-ci-publisher

## Overview

IAM policy `/ci/publisher` to publish (release) artifacts in AWS S3, ECR and CodeArtifact

This policy is designed to be used in the last step of a CI pipeline after artifacts have been built and are ready to be published (uploaded).
See GitHub Action [agilecustoms/release](https://github.com/agilecustoms/release)

The policy covers major types of artifact stores in AWS:
- S3 for arbitrary binaries, policy allows `s3:PutObject` in specified S3 bucket
- ECR for Docker images, policy allows `ecr:PutImage` in all ECR repos in the account
- CodeArtifact for software packages, policy allows `codeartifact:PublishPackageVersion` in specified CodeArtifact domain

Besides normal release, this policy also supports _dev-release_ (use input `dev=true`).
Dev-release allows developers to create a temporary version for testing from a feature branch.
Comprehensive documentation is available at GH action [agilecustoms/release](https://github.com/agilecustoms/release/blob/main/docs/features/dev-release.md)

To get read-only access to your CodeArtifact packages, see another module [terraform-aws-ci-builder](https://github.com/agilecustoms/terraform-aws-ci-builder)

## Highlights

- Publishes artifacts to S3, ECR, and CodeArtifact
- Follows least-privilege IAM principle per artifact type
- Supports OIDC (GitHub Actions, etc.)
- Enables semantic versioning workflows (e.g. `v1`, `v1.2`, `latest`)

## Usage

```hcl
module "publisher_policy" {
  source = "agilecustoms/ci-publisher/aws"

  account_id               = local.account_id  # AWS account ID, e.g. 123456789012
  region                   = "us-east-1"
  s3_bucket_name           = "my-company-dist" # {company}-dist is a good convention
  codeartifact_domain_name = "my-company"      # if you use CodeArtifact
}
```

## How to create a role with this policy

This module creates just policy, and here is a _recommendation_ how to create a role.
For roles used in CI pipelines, it is highly recommended to use [OIDC provider](https://github.com/aws-actions/configure-aws-credentials?tab=readme-ov-file#quick-start-oidc-recommended)
(not a service account with long living creds):
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
    # use one of the following conditions:
    # option 1: trust any repo in the org (good for dev-release)
    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider}:sub"
      values   = ["repo:${var.company}/*"]
    }
    # option 2: trust only main branch of any repo in the org
    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider}:sub"
      values   = ["repo:${var.company}/*:ref:refs/heads/main"]
    }
    # option 3: trust any repo which run Job with environment "release"
    # use this option for normal (non-dev) releases if you store PAT in environment secrets
    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider}:sub"
      values   = ["repo:${var.company}/*:environment:release"]
    }
  }
}

resource "aws_iam_role" "publisher" {
  path               = "/ci/"
  name               = "publisher" # "publisher-dev" for dev-releases
  description        = "Publishing artifacts in S3, ECR and CodeArtifact"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
}

module "publisher_policy" {
  source = "git::https://github.com/agilecustoms/terraform-aws-ci-publisher.git?ref=v1"

  account_id               = local.account_id
  codeartifact_domain_name = local.artifact_domain_name
  region                   = var.region
  s3_bucket_name           = aws_s3_bucket.dist.id
  dev                      = false # true for dev-release
}

resource "aws_iam_role_policy_attachment" "publisher" {
  role       = aws_iam_role.publisher.name
  policy_arn = module.publisher_policy.policy_arn
}
```

## Requirements

| Name                                                                      | Version   |
|---------------------------------------------------------------------------|-----------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7  |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 3.38.0 |

## Providers

| Name                                              | Version   |
|---------------------------------------------------|-----------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.38.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                   | Type     |
|------------------------------------------------------------------------------------------------------------------------|----------|
| [aws_iam_policy.publisher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/aws_iam_policy) | resource |

## Inputs

| Name                     | Default    | Description                                                                                                                                                                      |
|--------------------------|------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| account_id               |            | (required) AWS account ID where artifact stores (S3, ECR, CodeArtifact) are located                                                                                              |
| allow_delete             | true       | Allow deletion of ECR images and S3 objects. Useful for replacing floating tags like `latest`, `1.2`, and `1` when publishing a new version (e.g. `1.2.4`). Ignored in dev mode  |
| codeartifact_domain_name |            | CodeArtifact domain, typically just a company name. Leave empty if you don't use CodeArtifact. Ignored in dev mode                                                               |
| dev                      | false      | limits permissions to dev-release mode where any developer can publish from feature branch                                                                                       |
| iam_policy_path          | /ci/       | Use path to differentiate application roles, user roles and CI roles                                                                                                             |
| iam_policy_name          | publisher  | Name of the IAM policy                                                                                                                                                           |
| partition                | aws        | AWS partition, e.g. aws, aws-cn, aws-us-gov                                                                                                                                      |
| region                   |            | (required) AWS region where all artifacts are stored (S3, ECR, CodeArtifact)                                                                                                     |
| s3_bucket_name           |            | (required) S3 bucket name where all artifacts are stored                                                                                                                         |
| s3_dev_prefix            | */feature/ | dev-release is a release from feature branch. Use this prefix equal to feature branch prefix to distinguish from normal releases                                                 |
| s3_prefix                |            | Allows to narrow permissions only to certain path within a bucket, such as 'release/'. Should not be needed if you have a dedicated S3 bucket for artifacts. Ignored in dev mode |

## Outputs

| Name            | Description                                  |
|-----------------|----------------------------------------------|
| policy_arn      | ARN of the IAM policy created by this module |

## Authors

Module is maintained by [Alexey Chekulaev](https://github.com/laxa1986)

## License

Apache 2 Licensed. See [LICENSE](https://github.com/agilecustoms/terraform-aws-ci-publisher/blob/main/LICENSE) for full details

## Copyright

Copyright 2025 [Alexey Chekulaev](https://github.com/laxa1986)
