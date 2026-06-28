terraform {
  backend "s3" {
    bucket         = "michael-adesina-terraform-state-london"  # New bucket name
    key            = "capstone-phoenix/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks-london"  # New DynamoDB table name
    encrypt        = true
  }
}
