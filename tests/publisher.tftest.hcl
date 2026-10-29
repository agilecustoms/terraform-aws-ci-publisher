# Plan-only tests: aws_iam_policy_document is evaluated locally, so no AWS credentials are needed

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

variables {
  account_id     = "123456789012"
  region         = "us-east-1"
  s3_bucket_name = "acme-dist"
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_iam_policy.publisher.name == "publisher" && aws_iam_policy.publisher.path == "/ci/"
    error_message = "Policy must be /ci/publisher by default"
  }

  assert {
    condition = alltrue([for a in ["s3:ListBucket", "s3:PutObject", "s3:PutObjectTagging", "ecr:PutImage", "ecr:GetAuthorizationToken"] :
      contains(flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Action]), a)
    ])
    error_message = "S3 and ECR publish actions must be allowed"
  }

  assert {
    condition = length([for a in flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Action]) :
      a if startswith(a, "codeartifact:")
    ]) == 0
    error_message = "CodeArtifact actions must not be allowed when codeartifact_domain_name is empty"
  }

  assert {
    condition = alltrue([for a in ["s3:DeleteObject", "ecr:BatchDeleteImage"] :
      contains(flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Action]), a)
    ])
    error_message = "Delete actions must be allowed by default (allow_delete = true)"
  }

  assert {
    condition = contains(flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Resource]),
    "arn:aws:s3:::acme-dist/*")
    error_message = "S3 object resource must cover whole bucket when s3_prefix is empty"
  }
}

run "codeartifact" {
  command = plan

  variables {
    codeartifact_domain_name = "acme"
  }

  assert {
    condition = alltrue([for a in ["codeartifact:GetAuthorizationToken", "codeartifact:PublishPackageVersion", "sts:GetServiceBearerToken"] :
      contains(flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Action]), a)
    ])
    error_message = "CodeArtifact publish actions must be allowed when codeartifact_domain_name is set"
  }

  assert {
    condition = contains(flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Resource]),
    "arn:aws:codeartifact:us-east-1:123456789012:package/acme/*")
    error_message = "CodeArtifact package resource must be scoped to the domain"
  }
}

run "no_delete" {
  command = plan

  variables {
    allow_delete = false
  }

  assert {
    condition = length(setintersection(
      flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Action]),
      ["s3:DeleteObject", "ecr:BatchDeleteImage"]
    )) == 0
    error_message = "Delete actions must not be allowed when allow_delete = false"
  }
}

run "s3_prefix_and_partition" {
  command = plan

  variables {
    partition = "aws-cn"
    s3_prefix = "release/"
  }

  assert {
    condition = contains(flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Resource]),
    "arn:aws-cn:s3:::acme-dist/release/*")
    error_message = "S3 object resource must use partition and s3_prefix"
  }

  assert {
    condition = alltrue([for r in flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Resource]) :
      r == "*" || startswith(r, "arn:aws-cn:")
    ])
    error_message = "All ARNs must use the given partition"
  }
}

run "dev" {
  command = plan

  variables {
    dev                      = true
    codeartifact_domain_name = "acme"
  }

  assert {
    condition = length([for a in flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Action]) :
      a if startswith(a, "codeartifact:")
    ]) == 0
    error_message = "Dev policy must not allow CodeArtifact publishing"
  }

  assert {
    condition = length(setintersection(
      flatten([for s in jsondecode(aws_iam_policy.publisher.policy).Statement : s.Action]),
      ["s3:DeleteObject", "ecr:BatchDeleteImage"]
    )) == 0
    error_message = "Dev policy must not allow deletes"
  }

  assert {
    condition = anytrue([for s in jsondecode(aws_iam_policy.publisher.policy).Statement :
      s.Effect == "Allow"
      && contains(flatten([s.Action]), "s3:PutObject")
      && s.Resource == "arn:aws:s3:::acme-dist/*/feature/*"
      && try(s.Condition.StringEquals["s3:RequestObjectTag/Release"], null) == "false"
    ])
    error_message = "Dev policy must allow s3:PutObject only under s3_dev_prefix and only with tag Release=false"
  }

  assert {
    condition = anytrue([for s in jsondecode(aws_iam_policy.publisher.policy).Statement :
      s.Effect == "Deny"
      && contains(flatten([s.Action]), "s3:PutObjectTagging")
      && try(s.Condition.StringEquals["s3:ExistingObjectTag/Release"], null) == "true"
    ])
    error_message = "Dev policy must deny retagging objects that are already released (Release=true)"
  }
}
