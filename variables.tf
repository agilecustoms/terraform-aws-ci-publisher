variable "account_id" {
  type        = string
  description = "AWS account id where all artifacts are stored (S3, ECR, CodeArtifact)"
}

variable "allow_delete" {
  type        = bool
  default     = true
  description = "Allow to delete ECR images and S3 objects - given new version is '1.2.4', it allows to publish versions 'latest', '1.2' and '1'"
}

variable "codeartifact_domain_name" {
  type        = string
  default     = ""
  description = "CodeArtifact domain, typically just a company name. Keep default (empty) if you don't use CodeArtifact"
}

variable "dev" {
  type        = bool
  default     = false
  description = "limits permissions to dev-release mode where any developer can publish from feature branch"
}

variable "iam_policy_path" {
  type        = string
  default     = "/ci/"
  description = "use path to differentiate application roles, user roles and CI roles"
}

variable "iam_policy_name" {
  type        = string
  default     = "publisher"
  description = "Name of the IAM policy"
}

variable "partition" {
  type        = string
  default     = "aws"
  description = "AWS partition, e.g. aws, aws-cn, aws-us-gov"
}

variable "region" {
  type        = string
  description = "AWS region where all artifacts are stored (S3, ECR, CodeArtifact)"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name where all artifacts are stored"
}

variable "s3_dev_prefix" {
  type        = string
  default     = "*/feature/"
  description = "dev-release is a release from feature branch. Use this prefix equal to feature branch prefix to distinguish from normal releases"
}

variable "s3_prefix" {
  type        = string
  default     = ""
  description = "allows to narrow permissions only to certain path within a bucket, such as release/. Should not be needed if you have a dedicated S3 bucket for artifacts"
}
