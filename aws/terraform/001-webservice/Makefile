
.PHONY: all
all: webservice

.PHONY: clean
clean: webservice-clean

.PHONY: tools
tools: terraform


#############################################
# Terraform
#############################################

.PHONY: terraform
terraform: .ve/bin/terraform
.ve/bin/terraform:
	mkdir -p ".ve/bin"
	INSTALL_DIR=".ve/bin" ./bin/install-terraform.sh

terraform-clean:
	rm -f ".ve/bin/terraform"
	rm -f ,terraform-init

#############################################
# AWS Infrastructure
#############################################
.PHONY: webservice
,terraform-init:
	export PATH="$$PATH:$$PWD/.ve/bin" && terraform init
	touch $@

webservice terraform.tfstate: ,terraform-init
	export PATH="$$PATH:$$PWD/.ve/bin" && terraform apply -var-file all.tfvars

.PHONY: webservice-clean
webservice-clean:
	export PATH="$$PATH:$$PWD/.ve/bin" && terraform destroy -var-file all.tfvars
