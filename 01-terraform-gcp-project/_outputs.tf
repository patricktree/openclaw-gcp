output "project_id" {
  description = "The ID of the created project."
  value       = google_project.project.project_id
}

output "project_number" {
  description = "The numeric ID of the created project."
  value       = google_project.project.number
}

output "gcloud_cli_service_account_email" {
  description = "Email of the gcloud CLI service account with full project access."
  value       = google_service_account.gcloud_cli.email
}

output "gcloud_cli_service_account_key_json" {
  description = "Service account key JSON for gcloud CLI (sensitive)."
  value       = google_service_account_key.gcloud_cli.private_key
  sensitive   = true
}
