# GCP Infrastructure

1. Configure Terraform Variables and Backend:
   - Get the project ID from step 1:

     ```sh
     terraform -chdir=../01-terraform-gcp-project output -raw project_id
     ```

   - Copy [`./_backend.tf.template`](./_backend.tf.template) to `./_backend.tf` and replace `PROJECT_ID` by the GCP project id.
   - Copy [`./terraform.tfvars.template`](./terraform.tfvars.template) to `./terraform.tfvars` and replace `PROJECT_ID` by the GCP project id.

2. Initialize Terraform:

   ```sh
   cd ./02-terraform-gcp-resources
   terraform init
   ```

3. Run Terraform:

   ```sh
   terraform apply
   ```
