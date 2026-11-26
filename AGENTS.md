# AGENTS.md

Shared agilecustoms rules (git, code style) are in `../tools/agents/AGENTS.md`.
This file is `terraform-aws-ci-publisher` specific

`README.md` is its public page (GitHub, Terraform Registry): only user-facing content goes there, internals are here

## Tech summary

- Language: Terraform
- Artifact: Terraform Registry module `agilecustoms/ci-publisher/aws`, version = git tag `v{version}`,
  w/o floating tags (`floating-tags: false`), released by CI with *release* on push to `main`

## Context

*infrastructure-core* uses it for roles `ci/publisher` and dev-release publisher in the Dist account
(`aws/account_dist/role-publisher.tf`, `role-publisher-dev.tf`).
IAM policy created by this module is used in *release* GitHub Action

## Development

`make lint test-tf-validate test-tf`, all targets are in [Makefile](Makefile).
`test-tf` runs `terraform test` (`tests/publisher.tftest.hcl`) with `command = plan` and a provider
that skips AWS credentials.
`dev.tf`: policy statements for dev-release (`dev = true`).
`testing.md`: manual checks of the dev-release policy against a real bucket

## Documentation rules

- the repo is public: in docs and examples use placeholders (`my-company`, `123456789012`), not real ids
- README Inputs table must match `variables.tf` (names, required, defaults), Outputs table must match `outputs.tf`
