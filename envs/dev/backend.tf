# Bootstrap: create the S3 bucket and DynamoDB table once before running terraform init.
#
# aws s3api create-bucket --bucket <project>-tfstate --region us-east-1
# aws s3api put-bucket-versioning \
#   --bucket <project>-tfstate \
#   --versioning-configuration Status=Enabled
# aws dynamodb create-table \
#   --table-name <project>-tfstate-lock \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region us-east-1

terraform {
  backend "s3" {
    bucket         = "npc-awslab-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "npc-awslab-tfstate-lock"
    encrypt        = true
  }
}
