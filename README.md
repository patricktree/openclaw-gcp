# Clawdbot on GCP (Google Cloud Platform) via Terraform <!-- omit in toc -->

- [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [Create \& Configure GCP Project](#create--configure-gcp-project)
  - [Create GCP Infrastructure](#create-gcp-infrastructure)
  - [Install Docker on the GCP Ubuntu machine](#install-docker-on-the-gcp-ubuntu-machine)
  - [Setup Clawdbot](#setup-clawdbot)
- [How-To: Access Clawdbot Gateway (dashboard)](#how-to-access-clawdbot-gateway-dashboard)

## Setup

### Prerequisites

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
6. **Get a LLM Provider:** See full list here <https://docs.clawd.bot/providers>, e.g. Claude Code Pro ($20/month).

### Create & Configure GCP Project

1. **Use Terraform to create and configure a GCP project:** Run the steps outlined in [the README of `./01-terraform-gcp-project`](./01-terraform-gcp-project/README.md).
2. **Configure `gcloud` CLI for the created GCP project:**

   ```sh
   gcloud init
   # - when asked to choose a project, make sure to choose the new project
   # - when asked for default Compute Region and Zone, choose "[15] europe-west4-a"

   gcloud config get-value project
   # should print the correct GCP project ID

   gcloud auth application-default login
   # Terraform will now use your account to access GCP
   ```

### Create GCP Infrastructure

**Use Terraform to create the GCP infrastructure:** Run the steps outlined in [the README of `./02-terraform-gcp-infrastructure`](./02-terraform-gcp-infrastructure/README.md).

### Install Docker on the GCP Ubuntu machine

```sh
# connect to the GCP Ubuntu machine
gcloud compute ssh clawdbot

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

### Setup Clawdbot

```sh
# connect to the GCP Ubuntu machine
gcloud compute ssh clawdbot

# clone clawdbot
cd ~/
git clone https://github.com/patricktree/clawdbot.git"
cd ./clawdbot

# configure .env
cat <<'EOF' > .env
CLAWDBOT_HOME_VOLUME="clawdbot_home"
CLAWDBOT_GATEWAY_TOKEN="<some-random-value>"
EOF

# build and start Docker Compose setup
./docker-setup.sh
# during onboarding, choose the defaults except:
# - Enter Telegram bot token: <your token>
# - Telegram allowFrom (user id): <your Telegram user ID>
# - Configure skills now: Yes
#   - Preferred node manager: pnpm
#   - Skip for now

# start and setup tailscale
docker compose exec -d clawdbot-gateway tailscaled --tun=userspace-networking --statedir=/tmp/tailscale
docker compose exec clawdbot-gateway sh -c 'tailscale up --authkey=<your-tailscale-auth-key>'

# configure clawdbot gateway
docker compose run --rm clawdbot-cli configure
# configure gateway:
#   - Gateway bind mode: LAN
#   - Gateway auth: Token
#   - Tailscale exposure: Off
#   - For the token, set what you have defined as `CLAWDBOT_GATEWAY_TOKEN` before
```

## How-To: Access Clawdbot Gateway (dashboard)

1. Open <https://login.tailscale.com/admin/machines>.
2. Click on machine `clawdbot-gateway`.
3. Copy value of "Full domain".
4. Visit `https://<fulldomain>` on one of your devices which is also connected to your Tailscale VPN.
   - You should see the Clawdbot Gateway.
5. Click left on "Overview" --> enter the Gateway token in field "Gateway Token" --> Click on "Connect".
   - You should see `Health: OK` on the upper right of the gateway dashboard.
