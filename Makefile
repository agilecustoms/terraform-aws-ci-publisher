terraform-init:
	@terraform init -upgrade

terraform-validate:
	@terraform validate

terraform-format:
	@terraform fmt -recursive

release:
	@conventional-changelog -p angular -i CHANGELOG.md -s
