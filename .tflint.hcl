# https://github.com/terraform-linters/tflint, run: make terraform-lint
# Public module: all rules, callers see types and descriptions in the Terraform Registry
plugin "terraform" {
  enabled = true
  preset  = "all"
}

# offline rules only (invalid instance types, regions, etc), deep checks that call AWS API are off by default
plugin "aws" {
  enabled = true
  version = "0.50.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
