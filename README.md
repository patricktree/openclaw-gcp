# OpenClaw on GCP (Google Cloud Platform) via Terraform <!-- omit in toc -->

- [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [Create \& Configure GCP Project](#create--configure-gcp-project)
  - [Create GCP Infrastructure](#create-gcp-infrastructure)
  - [Install Docker on the GCP Ubuntu machine](#install-docker-on-the-gcp-ubuntu-machine)
  - [Setup OpenClaw](#setup-openclaw)
- [How-To: Access OpenClaw Gateway (dashboard)](#how-to-access-openclaw-gateway-dashboard)

## Setup

### Prerequisites

1. **Create a Telegram Bot:**
   1. Open Telegram.
   2. Contact `@botfather`, send text message `/start`.
   3. Send text message `/newbot`.
   4. Name `openclaw`
   5. Some username (e.g. `john_doe_openclaw_bot`).
   6. Remember the returned token.

2. **Get your Telegram User ID:**
   1. Open Telegram.
   2. Contact `@userinfobot`, send text message `/start`.
   3. Remember the returned ID for your user (e.g. `345123789`).

3. **Install the `gcloud` CLI:** [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install).
4. **Install Terraform:** [learn.hashicorp.com/tutorials/terraform/install-cli#install-terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli).
5. **Create a Tailscale account and create an auth key:** [tailscale.com/kb/1017/install](https://tailscale.com/kb/1017/install)
   - Create a personal account.
   - Create an auth key:
     - Visit <https://login.tailscale.com/admin/settings/keys>.
     - Click "Generate auth key..." and then "Generate key" (no need to fill out anything).
     - Remember the auth key.
6. **Get a LLM Provider:** See full list here <https://docs.openclaw.ai/providers>, e.g. Claude Code Pro ($20/month).

### Create & Configure GCP Project

1. **Use Terraform to create and configure a GCP project:** Run the steps outlined in [the README of `./01-terraform-gcp-project`](./01-terraform-gcp-project/README.md).
2. **Configure `gcloud` CLI with the service account key created by Terraform:**

   ```sh
   mkdir -p .secrets
   KEY_FILE=".secrets/gcloud-cli-key.json"

   terraform -chdir=01-terraform-gcp-project output -raw gcloud_cli_service_account_key_json | base64 --decode > "$KEY_FILE"
   PROJECT_ID="$(terraform -chdir=01-terraform-gcp-project output -raw project_id)"

   gcloud config configurations create gcloud-cli-openclaw
   gcloud config configurations activate gcloud-cli-openclaw
   gcloud config set project "$PROJECT_ID"
   gcloud auth activate-service-account --key-file "$KEY_FILE" --project "$PROJECT_ID"

   gcloud config get-value project
   gcloud auth list
   ```

### Create GCP Infrastructure

**Use Terraform to create the GCP infrastructure:** Run the steps outlined in [the README of `./02-terraform-gcp-infrastructure`](./02-terraform-gcp-infrastructure/README.md).

### Install Docker on the GCP Ubuntu machine

```sh
# get the instance name (MIG adds a random suffix)
INSTANCE=$(gcloud compute instances list --filter="name~^openclaw" --format="value(name)")

# connect via IAP tunnel (secure - no public SSH exposure)
gcloud compute ssh $INSTANCE --tunnel-through-iap

# install and configure Docker
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
```

### Setup OpenClaw

```sh
# get the instance name (MIG adds a random suffix)
INSTANCE=$(gcloud compute instances list --filter="name~^openclaw" --format="value(name)")

# connect via IAP tunnel (secure - no public SSH exposure)
gcloud compute ssh $INSTANCE --tunnel-through-iap

# clone openclaw
cd ~/
git clone https://github.com/patricktree/openclaw.git
cd ./openclaw

# configure .env
cat <<'EOF' > .env
TAILSCALE_AUTHKEY="<your-tailscale-auth-key>"
OPENCLAW_GATEWAY_TOKEN="<some-random-value>"
EOF

# build and start Docker Compose setup
./docker-setup.sh
# during onboarding, choose the defaults except:
# - Enter Telegram bot token: <your token>
# - Telegram allowFrom (user id): <your Telegram user ID>
# - Configure skills now: Yes
#   - Preferred node manager: pnpm
#   - Skip for now

# start tailscale serve
docker compose exec tailscale tailscale serve --bg 18789

# configure openclaw gateway
docker compose run --rm openclaw-cli configure
# configure gateway:
#   - Gateway bind mode: LAN
#   - Gateway auth: Token
#   - Tailscale exposure: Off
#   - For the token, set what you have defined as `OPENCLAW_GATEWAY_TOKEN` before
```

## How-To: Access OpenClaw Gateway (dashboard)

1. Open <https://login.tailscale.com/admin/machines>.
2. Click on machine `openclaw-gateway`.
3. Copy value of "Full domain".
4. Visit `https://<fulldomain>` on one of your devices which is also connected to your Tailscale VPN.
   - You should see the OpenClaw Gateway.
5. Click left on "Overview" --> enter the Gateway token in field "Gateway Token" --> Click on "Connect".
   - You should see `Health: OK` on the upper right of the gateway dashboard.
