# Bootstrap: create the S3 bucket once before running terraform init.
#
# aws s3api create-bucket --bucket npc-awslab-tfstate --region us-east-1
# aws s3api put-bucket-versioning \
#   --bucket npc-awslab-tfstate \
#   --versioning-configuration Status=Enabled

terraform {
  backend "s3" {
    bucket       = "npc-awslab-tfstate"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
