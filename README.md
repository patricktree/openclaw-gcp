# Clawdbot on GCP via Terraform

- [Clawdbot on GCP via Terraform](#clawdbot-on-gcp-via-terraform)
  - [Prerequisites](#prerequisites)
  - [Create \& Configure GCP Project](#create--configure-gcp-project)
  - [Create GCP Infrastructure](#create-gcp-infrastructure)

## Prerequisites

1. **Install the `gcloud` CLI:** See [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install).
2. **Install Terraform:** See [learn.hashicorp.com/tutorials/terraform/install-cli#install-terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli).

## Create & Configure GCP Project

**Use Terraform to create and configure a GCP project:** Run the steps outlined in [the README of `./01-terraform-gcp-project`](./01-terraform-gcp-project/README.md).

Then, make sure that `gcloud` CLI is configured for the GCP project you want to operate on:

```sh
gcloud init # when asked to choose a project, make sure to choose the new project. when asked for default Compute Region and Zone, choose "[15] europe-west4-a"
gcloud config get-value project # should print the correct GCP project ID
gcloud auth application-default login # Terraform will now use your account to access GCP
```

## Create GCP Infrastructure

See [the README of `./02-terraform-gcp-infrastructure`](./02-terraform-gcp-infrastructure/README.md).
