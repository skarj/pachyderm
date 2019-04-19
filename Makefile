EXECUTABLES = gcloud kubectl helm curl
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

.PHONY: authorize-gcp install-helm install-pachyderm install-pachctl pachyderm-portforward


authorize-gcp:
	@echo ""
	@echo "=================================="
	@echo "        Authorizing in GCP        "
	@echo "=================================="

	gcloud/authorize.sh

install-helm: authorize-gcp
	@echo ""
	@echo "=================================="
	@echo "      Installing Helm Tiller      "
	@echo "=================================="

	kubectl apply -f gcloud/helm/helm-tiller
	helm init --service-account tiller

install-pachyderm: authorize-gcp
	@echo ""
	@echo "=================================="
	@echo "       Installing Pachyderm       "
	@echo "=================================="

	helm install stable/pachyderm --name pachyderm --namespace pachyderm -f gcloud/helm/values.yaml

install-pachctl:
	@echo ""
	@echo "=================================="
	@echo "     Installing Pachyderm CLI     "
	@echo "=================================="

	curl -o /tmp/pachctl.deb -L https://github.com/pachyderm/pachyderm/releases/download/v1.8.6/pachctl_1.8.6_amd64.deb && sudo dpkg -i /tmp/pachctl.deb

pachyderm-portforward: authorize-gcp
	@echo ""
	@echo "=================================="
	@echo "     Forwarding Pachyderm Port    "
	@echo "=================================="

	pachctl --namespace=pachyderm port-forward &
