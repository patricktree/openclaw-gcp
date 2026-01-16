variable "project_id" {
  description = "GCP project ID"
  type        = string
}

locals {
  region = "europe-west4"
  zone   = "europe-west4-a"
}
