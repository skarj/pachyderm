# Terraform config
variable "pachyderm_data_bucket_name" {
  type = "string"
}
resource "google_storage_bucket" "pachyderm" {
  name = "${var.pachyderm_data_bucket_name}"
}
