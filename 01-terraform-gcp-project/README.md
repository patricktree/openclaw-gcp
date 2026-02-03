# GCP Project

1. Authenticate Terraform to create the project (account needs org/billing permissions):

   ```sh
   gcloud init # choose any project when asked to do so (we create a new one now anyways)
   gcloud auth application-default login # Terraform will now use your account to access GCP
   ```

2. Set Terraform variables:  
   Copy [`./terraform.tfvars.template`](./terraform.tfvars.template) to `./terraform.tfvars` and replace all placeholders by suitable values.
   - You can get your `BILLING_ACCOUNT_ID` from [console.cloud.google.com/billing](https://console.cloud.google.com/billing).

3. Initialize Terraform:

   ```sh
   cd ./01-terraform-gcp-project
   terraform init
   ```

4. Run Terraform:

   ```sh
   terraform apply
   ```

5. Create a service account key + gcloud CLI config (key is sensitive):

   ```sh
   mkdir -p ../.secrets
   KEY_FILE="../.secrets/gcloud-cli-key.json"

   terraform output -raw gcloud_cli_service_account_key_json | base64 --decode > "$KEY_FILE"
   PROJECT_ID="$(terraform output -raw project_id)"

   gcloud config configurations create gcloud-cli-clawdbot
   gcloud config configurations activate gcloud-cli-clawdbot
   gcloud config set project "$PROJECT_ID"
   gcloud auth activate-service-account --key-file "$KEY_FILE" --project "$PROJECT_ID"
   ```
