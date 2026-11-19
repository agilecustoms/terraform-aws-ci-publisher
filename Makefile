deps-install:
	@terraform init

deps-update:
	@terraform init -upgrade

# format check, then tflint (config in .tflint.hcl, --init installs ruleset plugins once, then no-op).
# Needs tflint, see Confluence "Basic setup"
# fix: terraform fmt -recursive
lint:
	@terraform fmt -check -recursive && tflint --init && tflint --format compact

test-tf-validate:
	@terraform validate

test-tf:
	@terraform test
