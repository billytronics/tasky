terraform {
  # --- S3 Backend Configuration ---
  # This block defines where Terraform stores its state file and handles locking.
  backend "s3" {
    bucket         = "billy-tasky-tf-state"
    key            = "tasky/terraform.tfstate" # bucket path
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"    # DynamoDB table for state locking
  }
}
