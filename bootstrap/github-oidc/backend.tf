# Reuses the same state bucket as the main infrastructure, under a separate key.
terraform {
  backend "s3" {
    bucket         = "npc-awslab-tfstate"
    key            = "bootstrap/github-oidc.tfstate"
    region         = "us-east-1"
    dynamodb_table = "npc-awslab-tfstate-lock"
    encrypt        = true
  }
}
