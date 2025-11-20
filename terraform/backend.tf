terraform {
  backend "s3" {
    bucket         = "harish-sentry-tfstate-v1"
    key            = "dev/eks/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "sentry-tfstate-lock"
  }
}