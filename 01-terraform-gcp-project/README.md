# GCP Project

1. Configure `gcloud` and get credentials for Terraform:

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
