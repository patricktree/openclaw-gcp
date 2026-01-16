# Clawdbot on GCP via Terraform

- [Clawdbot on GCP via Terraform](#clawdbot-on-gcp-via-terraform)
  - [Prerequisites](#prerequisites)
  - [Create \& Configure GCP Project](#create--configure-gcp-project)
  - [Create GCP Infrastructure](#create-gcp-infrastructure)
  - [TODO](#todo)

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

## TODO

```sh
gcloud compute ssh clawdbot

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
newgrp docker

git clone https://github.com/patricktree/clawdbot.git"
cd ./clawdbot
cat <<'EOF' > .env
CLAWDBOT_HOME_VOLUME="clawdbot_home"
CLAWDBOT_DOCKER_APT_PACKAGES="build-essential curl file git"
EOF
./docker-setup.sh

docker compose -f /home/pkerschbaum/clawdbot/docker-compose.yml run --rm clawdbot-cli configure
# configure gateway: bind LAN, copy token at the end

# Open host port to VM port for Gateway
gcloud compute ssh clawdbot -- -N -L 18789:localhost:18789

# Write the bot via Telegram, it sends you back a code. Then:
docker compose -f /home/pkerschbaum/clawdbot/docker-compose.yml run --rm clawdbot-cli pairing approve telegram <code>
```
