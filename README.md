# Clawdbot on GCP (Google Cloud Platform) via Terraform <!-- omit in toc -->

- [Prerequisites](#prerequisites)
- [Create \& Configure GCP Project](#create--configure-gcp-project)
- [Create GCP Infrastructure](#create-gcp-infrastructure)
- [Install Docker on the Ubuntu machine](#install-docker-on-the-ubuntu-machine)
- [Setup Clawdbot](#setup-clawdbot)
- [Access Clawdbot Gateway (dashboard)](#access-clawdbot-gateway-dashboard)

## Prerequisites

1. **Create a Telegram Bot:**
   1. Open Telegram.
   2. Contact `@botfather`, send text message `/start`.
   3. Send text message `/newbot`.
   4. Name `clawdbot`
   5. Some username (e.g. `john_doe_clawdbot`).
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

## Create & Configure GCP Project

1. **Use Terraform to create and configure a GCP project:** Run the steps outlined in [the README of `./01-terraform-gcp-project`](./01-terraform-gcp-project/README.md).
2. **Configure `gcloud` CLI the created GCP project:**

   ```sh
   gcloud init
   # - when asked to choose a project, make sure to choose the new project
   # - when asked for default Compute Region and Zone, choose "[15] europe-west4-a"

   gcloud config get-value project
   # should print the correct GCP project ID

   gcloud auth application-default login
   # Terraform will now use your account to access GCP
   ```

## Create GCP Infrastructure

1. **Use Terraform to create the GCP infrastructure:** Run the steps outlined in [the README of `./02-terraform-gcp-infrastructure`](./02-terraform-gcp-infrastructure/README.md).

## Install Docker on the Ubuntu machine

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
```

## Setup Clawdbot

```sh
gcloud compute ssh clawdbot

cd ~/
git clone https://github.com/patricktree/clawdbot.git"
cd ./clawdbot

cat <<'EOF' > .env
CLAWDBOT_HOME_VOLUME="clawdbot_home"
TAILSCALE_AUTHKEY="<your-tailscale-auth-key>"
EOF

./docker-setup.sh
# during onboarding, choose the defaults except:
# - Enter Telegram bot token: <your token>
# - Telegram allowFrom (user id): <your Telegram user ID>
# - Configure skills now: Yes
#   - Preferred node manager: pnpm
#   - Skip for now

docker compose -f ./docker-compose.yml run --rm clawdbot-cli configure
# configure gateway:
#   - Gateway bind mode: LAN
#   - Gateway auth: Token
#   - Tailscale exposure: Off
#   - Copy the token
```

## Access Clawdbot Gateway (dashboard)

1. Open <https://login.tailscale.com/admin/machines>.
2. Click on machine `clawdbot-gateway`.
3. Copy value of "Full domain".
4. Visit `http://<fulldomain>:18789`.
   - You should see the Clawdbot Gateway.
5. Click left on "Overview" --> enter the token in field "Gateway Token" --> "Connect".
   - You should see `Health: OK` on the upper right of the gateway dashboard.
