# OpenClaw on GCP (Google Cloud Platform) via Terraform <!-- omit in toc -->

- [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [Create \& Configure GCP Project](#create--configure-gcp-project)
  - [Create GCP Infrastructure](#create-gcp-infrastructure)
  - [Install Docker on the GCP Ubuntu machine](#install-docker-on-the-gcp-ubuntu-machine)
  - [Setup OpenClaw](#setup-openclaw)
  - [Start Telegram conversation with your bot](#start-telegram-conversation-with-your-bot)
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

# enable case-insensitive search and history search with arrow keys in the terminal
echo -e "set completion-ignore-case on\n\"\e[A\": history-search-backward\n\"\e[B\": history-search-forward" >> ~/.inputrc && bind -f ~/.inputrc

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
EOF

# build and start Docker Compose setup
./docker-setup.sh
# during onboarding, configure everything as needed.
# some recommended answers:
#   - Configure skills now: Yes
#     - Preferred node manager: pnpm
#     - Skip for now
#   - Enable hooks: Skip for now
#   - Enable zsh shell completion for openclaw: no
# it will hang at "Onboarding complete. Use the dashboard link above to control OpenClaw."
# hit CTRL+C there

# start everything
docker compose up -d

# the onboarding wizard generates its own token which may differ from the one
# docker-setup.sh wrote to .env. The gateway reads from its config file, so
# .env must match for CLI commands and the dashboard to authenticate correctly.
# so, sync the gateway token from the config to .env.
CONFIG_TOKEN=$(docker compose exec openclaw-gateway node dist/index.js config get gateway.auth.token 2>/dev/null | tr -d '"[:space:]')
sed -i "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=$CONFIG_TOKEN/" .env
docker compose restart openclaw-gateway

# start tailscale serve
docker compose exec tailscale tailscale serve --bg 18789
# this will print the Tailscale URL for the OpenClaw gateway dashboard like "https://openclaw-gateway.tail8b23f9.ts.net/"
```

### Start Telegram conversation with your bot

1. Open Telegram.
2. Search for the bot username you created (e.g. `john_doe_openclaw_bot`) and start a conversation.
3. Send the message `/start` to the bot.
   - It will reply with "OpenClaw: acccess not configured."
4. SSH into the VM and approve the Telegram pairing request:

   ```sh
   # get the instance name (MIG adds a random suffix)
   INSTANCE=$(gcloud compute instances list --filter="name~^openclaw" --format="value(name)")

   # connect via IAP tunnel (secure - no public SSH exposure)
   gcloud compute ssh $INSTANCE --tunnel-through-iap

   cd ~/openclaw

   docker compose run --rm openclaw-cli pairing approve telegram <code>
   ```

5. Write "hello" to the bot in Telegram.
   - It should reply now and start the "soul" process ("who am I?" etc).

## How-To: Access OpenClaw Gateway (dashboard)

1. Open <https://login.tailscale.com/admin/machines>.
2. Click on machine `openclaw-gateway`.
3. Copy value of "Full domain" (the Tailscale URL for the OpenClaw gateway dashboard).
4. Visit the URL on one of your devices which is also connected to your Tailscale VPN.
   - You should see the OpenClaw gateway dashboard.
5. On the "Overview" page, paste the gateway token (value of `OPENCLAW_GATEWAY_TOKEN` in `.env`) into the "Gateway Token" field and click "Connect".
   - You will see error `disconnected (1008): pairing required`. This is expected — the dashboard device needs to be approved.
6. SSH into the VM and approve the dashboard's pairing request:

   ```sh
   # get the instance name (MIG adds a random suffix)
   INSTANCE=$(gcloud compute instances list --filter="name~^openclaw" --format="value(name)")

   # connect via IAP tunnel (secure - no public SSH exposure)
   gcloud compute ssh $INSTANCE --tunnel-through-iap

   cd ~/openclaw

   # list devices — you should see 1 pending request from the dashboard
   docker compose run --rm openclaw-cli devices list

   # approve it (use the Request ID from the Pending table)
   docker compose run --rm openclaw-cli devices approve <request-id>
   ```

7. Go back to the browser dashboard and click "Connect" again.
   - The dashboard should now show "Connected" with status and uptime info.
