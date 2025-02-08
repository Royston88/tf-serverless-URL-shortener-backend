terraform {
  backend "s3" {
    bucket = "sctp-ce8-tfstate"
    region = "ap-southeast-1"
    key    = "group1-tf-serverless-url-shortener-backend.tfstate"
  }
}