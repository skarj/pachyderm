# Terraform config
variable "pachyderm_data_bucket_name" {
  type = "string"
}

variable "pachyderm_namespace" {
  type = "string"
}
resource "google_storage_bucket" "data_bucket" {
  name = "${var.pachyderm_data_bucket_name}"
  force_destroy = true
}

resource "google_container_cluster" "pachyderm" {

  name               = "pachyderm"
  description        = "Pachyderm cluster"
  location           = "us-central1-a"

  remove_default_node_pool = true
  initial_node_count = 1

}

resource "google_container_node_pool" "pachyderm" {
  name       = "pachyderm-node-pool"
  location   = "us-central1-a"
  cluster    = "${google_container_cluster.pachyderm.name}"
  node_count = 3

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_write"
    ]
  }
}

provider "kubernetes" {
  host = "https://${google_container_cluster.pachyderm.endpoint}"
  username = "${google_container_cluster.pachyderm.master_auth.0.username}"
  password = "${google_container_cluster.pachyderm.master_auth.0.password}"
  client_certificate = "${base64decode(google_container_cluster.pachyderm.master_auth.0.client_certificate)}"
  client_key = "${base64decode(google_container_cluster.pachyderm.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.pachyderm.master_auth.0.cluster_ca_certificate)}"
}

resource "kubernetes_namespace" "pachyderm" {
  metadata {
    name = "${var.pachyderm_namespace}"
  }
}
