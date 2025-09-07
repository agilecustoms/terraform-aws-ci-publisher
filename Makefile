terraform-init:
	@terraform init -upgrade

terraform-validate:
	@terraform validate

terraform-format:
	@terraform fmt -recursive
