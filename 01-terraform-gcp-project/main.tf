locals {
  project_name = "clawdbot-project"
}

resource "random_id" "project_id" {
  byte_length = 4
  prefix      = "${local.project_name}-"
}

resource "google_project" "project" {
  project_id      = random_id.project_id.hex
  name            = local.project_name
  org_id          = var.org_id
  billing_account = var.billing_account_id

  auto_create_network = "false" # do not create the "default" VPC network

  deletion_policy = "ABANDON" # the project is not shut down when "terraform destroy" is run. Shut down the project via Google Cloud console or gcloud CLI instead.
}

resource "google_service_account" "gcloud_cli" {
  project      = google_project.project.project_id
  account_id   = "gcloud-cli"
  display_name = "gcloud-cli"
  description  = "Service account for gcloud CLI with full access to the project."
}

resource "google_project_iam_member" "gcloud_cli_owner" {
  project = google_project.project.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.gcloud_cli.email}"
}

resource "google_service_account_key" "gcloud_cli" {
  service_account_id = google_service_account.gcloud_cli.name
}

# Enable IAP API for SSH tunneling
resource "google_project_service" "iap" {
  project = google_project.project.project_id
  service = "iap.googleapis.com"

  disable_on_destroy = false
}

resource "google_storage_bucket" "tfstate" {
  project                     = google_project.project.project_id
  name                        = "${google_project.project.project_id}_tfstate"
  location                    = local.region
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # set up lifecycle rule to only retain the latest 30 versions of any tfstate
  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      with_state         = "ARCHIVED"
      num_newer_versions = 30
    }
  }
}
