SHELL := /bin/bash

EXECUTABLES = gcloud terraform kubectl curl
K := $(foreach exec, $(EXECUTABLES), \
    $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

.PHONY: infrastructure pachctl install uninstall portforward killforward clean repo pipelines

# For the persistent disk, 10GB is a good size to start with.
# This stores PFS metadata. For reference, 1GB
# should work fine for 1000 commits on 1000 files.
# STORAGE_SIZE=<the size of the volume that you are going to create, in GBs. e.g. "10">
STORAGE_SIZE = 10

# The Pachyderm bucket name needs to be globally unique across the entire GCP region.
# BUCKET_NAME=<The name of the GCS bucket where your data will be stored>
BUCKET_NAME = pachyderm-data-test

NAMESPACE = pachyderm


infrastructure:
	@echo ""
	@echo "=================================="
	@echo "      Creating infrastructure     "
	@echo "=================================="

	source gcloud/authorize.sh && \
	terraform init gcloud/terraform && \
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

install: infrastructure
	@echo ""
	@echo "=================================="
	@echo "       Installing Pachyderm       "
	@echo "=================================="

	# https://github.com/pachyderm/pachyderm/issues/2787
	source gcloud/authorize.sh && \
	kubectl create clusterrolebinding cluster-admin-binding \
		--clusterrole cluster-admin \
		--user $(shell gcloud config get-value account) 2>/dev/null; true

	source gcloud/authorize.sh && \
	pachctl deploy google ${BUCKET_NAME} ${STORAGE_SIZE} \
		--namespace=${NAMESPACE} \
		--dynamic-etcd-nodes=1 \
		--etcd-cpu-request=250m \
		--etcd-memory-request=256M \
		--pachd-cpu-request=250m \
		--pachd-memory-request=512M

uninstall:
	@echo ""
	@echo "=================================="
	@echo "      Uninstalling Pachyderm      "
	@echo "=================================="

	source gcloud/authorize.sh && \
	pachctl undeploy --all --namespace=${NAMESPACE}

killforward:
	killall pachctl 2>/dev/null || true

portforward: killforward
	@echo ""
	@echo "=================================="
	@echo "     Forwarding Pachyderm Port    "
	@echo "=================================="

	source gcloud/authorize.sh && \
	pachctl port-forward --namespace=${NAMESPACE} &

clean: killforward uninstall
	@echo ""
	@echo "=================================="
	@echo "      Cleaning everything         "
	@echo "=================================="

	source gcloud/authorize.sh && \
	terraform destroy \
		-var pachyderm_data_bucket_name=${BUCKET_NAME} \
		-var pachyderm_namespace=${NAMESPACE} \
		-auto-approve \
		gcloud/terraform

repo: portforward
	@echo ""
	@echo "=================================="
	@echo "      Cleaning repository         "
	@echo "=================================="

	pachctl create-repo images
	pachctl put-file images master liberty.png -f http://imgur.com/46Q8nDz.png
	pachctl put-file images master AT-AT.png -f http://imgur.com/8MN9Kg0.png
	pachctl put-file images master kitten.png -f http://imgur.com/g2QnNqa.png

pipelines: portforward
	@echo ""
	@echo "=================================="
	@echo "      Cleaning pipelines          "
	@echo "=================================="

	pachctl create-pipeline -f pipelines/montage/montage.json
	pachctl create-pipeline -f pipelines/edges/edges.json
