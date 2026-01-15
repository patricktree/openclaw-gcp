terraform {
  required_version = ">= 1.0"

  backend "gcs" {
    bucket = "playground-pkerschbaum-tfstate"
    prefix = "clawdbot"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
  zone    = local.zone
}
