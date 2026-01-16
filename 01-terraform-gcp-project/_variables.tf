locals {
  region = "europe-west4"
  zone   = "europe-west4-a"
}

variable "org_id" {
  description = "Optional organization ID to create the project under."
  type        = string
  default     = null
}

variable "billing_account_id" {
  description = "Optional billing account ID to associate with the project."
  type        = string
}
