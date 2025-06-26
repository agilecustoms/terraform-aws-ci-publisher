variable "account_id" {
  description = "AWS account id where all artifacts are stored (S3, ECR, CodeArtifact)"
}

variable "allow_delete" {
  type        = bool
  default     = true
  description = "Allow to delete ECR images and S3 objects - given new version is '1.2.4', it allows to publish versions 'latest', '1.2' and '1'"
}

variable "codeartifact_domain_name" {
  default     = ""
  description = "CodeArtifact domain, typically just a company name. Keep default (empty) if you don't use CodeArtifact"
}

variable "iam_policy_path" {
  default     = "/ci/"
  description = "use path to differentiate application roles, user roles and CI roles"
}

variable "iam_policy_name" {
  default = "publisher"
}

variable "partition" {
  default     = "aws"
  description = "AWS partition, e.g. aws, aws-cn, aws-us-gov"
}

variable "region" {
  description = "AWS region where all artifacts are stored (S3, ECR, CodeArtifact)"
}

variable "s3_bucket_name" {
  description = "S3 bucket name where all artifacts are stored"
}

variable "s3_prefix" {
  default     = ""
  description = "allows to narrow permissions only to certain path within a bucket, such as /release. Should not be needed if you have a dedicated S3 bucket for artifacts"
}
