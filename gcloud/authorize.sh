#!/bin/bash

# GCP account properties
gcp_creds=~/.config/gcloud/quixotic-being-214814.json
gcp_project=quixotic-being-214814
gcp_region=us-central1

# GKE cluster properties
gke_cluster=pachyderm
gke_zone=us-central1-a
gke_namespace=pachyderm

unset GCLOUD_KEYFILE_JSON
unset GCLOUD_REGION
unset GCLOUD_PROJECT
unset GCP_PROJECT
unset CLOUDSDK_CORE_PROJECT
unset CLOUDSDK_CONTAINER_USE_CLIENT_CERTIFICATE
unset GOOGLE_APPLICATION_CREDENTIALS
unset GKE_CLUSTER_NAME

# Terraform environment variables
export GCLOUD_KEYFILE_JSON=$gcp_creds
export GCLOUD_REGION=$gcp_region
export GCLOUD_PROJECT=$gcp_project
printf "Exported environment variables for terraform. Project: $gcp_project.\n"

# Gcloud SDK environment variables
export GCP_PROJECT=$gcp_project
export CLOUDSDK_CORE_PROJECT=$gcp_project
export CLOUDSDK_CONTAINER_USE_CLIENT_CERTIFICATE=False
export GOOGLE_APPLICATION_CREDENTIALS=$gcp_creds
gcloud auth activate-service-account --key-file $gcp_creds \
  && printf "Exported environment variables for Gcloud SDK. Project: $gcp_project\n\n"

# Gcloud SDK environment variables
export GKE_CLUSTER_NAME=$gke_cluster

# GKE cluster credentials
gcloud container clusters get-credentials $gke_cluster --zone $gke_zone --project $gcp_project \
  && kubectl config set-context $(kubectl config current-context) --namespace=$gke_namespace
