variable "account_id" {}

variable "allow_override" {
  type    = bool
  default = true
}

variable "codeartifact_domain_name" {
  default = null
}

variable "iam_path" {
  default = "/ci/"
}

variable "iam_role_name" {
  default = "publisher"
}

variable "partition" {
  default = "aws"
}

variable "region" {}

variable "s3_bucket_name" {}

variable "s3_prefix" {
  default     = ""
  description = "in case you store your objects in subfolder such as /release"
}
