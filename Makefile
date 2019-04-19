SHELL := /bin/bash

EXECUTABLES = gcloud terraform kubectl curl
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

.PHONY: gcp-authorize gcp-makebucket install-pachctl install-pachyderm pachyderm-portforward

# For the persistent disk, 10GB is a good size to start with.
# This stores PFS metadata. For reference, 1GB
# should work fine for 1000 commits on 1000 files.
# STORAGE_SIZE=<the size of the volume that you are going to create, in GBs. e.g. "10">
STORAGE_SIZE = 10

# The Pachyderm bucket name needs to be globally unique across the entire GCP region.
# BUCKET_NAME=<The name of the GCS bucket where your data will be stored>
BUCKET_NAME = pachyderm-data-test


gcp-authorize:
	@echo ""
	@echo "=================================="
	@echo "        Authorizing in GCP        "
	@echo "=================================="

	source gcloud/authorize.sh

gcp-makebucket: gcp-authorize
	@echo ""
	@echo "=================================="
	@echo "      Creating bucket in GCP      "
	@echo "=================================="

	terraform init gcloud/terraform
	terraform apply -var pachyderm_data_bucket_name=${BUCKET_NAME} gcloud/terraform

install-pachctl:
	@echo ""
	@echo "=================================="
	@echo "     Installing Pachyderm CLI     "
	@echo "=================================="

	curl -o /tmp/pachctl.deb -L https://github.com/pachyderm/pachyderm/releases/download/v1.8.6/pachctl_1.8.6_amd64.deb \
		&& sudo dpkg -i /tmp/pachctl.deb

install-pachyderm: gcp-authorize install-pachctl gcp-makebucket
	@echo ""
	@echo "=================================="
	@echo "       Installing Pachyderm       "
	@echo "=================================="

	pachctl deploy google ${BUCKET_NAME} ${STORAGE_SIZE} --dynamic-etcd-nodes=1

pachyderm-portforward: gcp-authorize
	@echo ""
	@echo "=================================="
	@echo "     Forwarding Pachyderm Port    "
	@echo "=================================="

	pachctl --namespace=pachyderm port-forward &
