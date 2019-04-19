SHELL := /bin/bash

EXECUTABLES = gcloud terraform kubectl curl
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

.PHONY: authorize infrastructure pachctl pachyderm uninstall portforward

# For the persistent disk, 10GB is a good size to start with.
# This stores PFS metadata. For reference, 1GB
# should work fine for 1000 commits on 1000 files.
# STORAGE_SIZE=<the size of the volume that you are going to create, in GBs. e.g. "10">
STORAGE_SIZE = 10

# The Pachyderm bucket name needs to be globally unique across the entire GCP region.
# BUCKET_NAME=<The name of the GCS bucket where your data will be stored>
BUCKET_NAME = pachyderm-data-test
NAMESPACE=pachyderm

authorize:
	@echo ""
	@echo "=================================="
	@echo "            Authorize	         "
	@echo "=================================="

	source gcloud/authorize.sh

infrastructure: authorize
	@echo ""
	@echo "=================================="
	@echo "      Creating infrastructure	 "
	@echo "=================================="

	terraform init gcloud/terraform
	terraform apply \
		-var pachyderm_data_bucket_name=${BUCKET_NAME} \
		-var pachyderm_namespace=${NAMESPACE} \
		gcloud/terraform

pachctl:
	@echo ""
	@echo "=================================="
	@echo "     Installing Pachyderm CLI     "
	@echo "=================================="

	curl -o /tmp/pachctl.deb -L https://github.com/pachyderm/pachyderm/releases/download/v1.8.6/pachctl_1.8.6_amd64.deb \
		&& sudo dpkg -i /tmp/pachctl.deb

install: authorize infrastructure
	@echo ""
	@echo "=================================="
	@echo "       Installing Pachyderm       "
	@echo "=================================="

	# https://github.com/pachyderm/pachyderm/issues/2787
	kubectl create clusterrolebinding cluster-admin-binding \
		--clusterrole cluster-admin \
		--user $(shell gcloud config get-value account) 2>/dev/null; true

	pachctl deploy google ${BUCKET_NAME} ${STORAGE_SIZE} \
		--namespace=${NAMESPACE} \
		--dynamic-etcd-nodes=1 \
		--etcd-cpu-request=250m \
		--etcd-memory-request=256M \
		--pachd-cpu-request=250m \
		--pachd-memory-request=512M

uninstall: authorize
	@echo ""
	@echo "=================================="
	@echo "      Uninstalling Pachyderm      "
	@echo "=================================="


	pachctl undeploy --all --namespace=${NAMESPACE}

killforward:
	killall pachctl 2>/dev/null || true

portforward: killforward authorize
	@echo ""
	@echo "=================================="
	@echo "     Forwarding Pachyderm Port    "
	@echo "=================================="

	pachctl port-forward --namespace=${NAMESPACE} &

clean: killforward uninstall
	@echo ""
	@echo "=================================="
	@echo "       Cleaning everything	     "
	@echo "=================================="

	terraform destroy \
		-var pachyderm_data_bucket_name=${BUCKET_NAME} \
		-var pachyderm_namespace=${NAMESPACE} \
		gcloud/terraform
