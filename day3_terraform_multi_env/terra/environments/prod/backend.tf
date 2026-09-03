terraform {
  backend "s3" {
    bucket  = "gsharma1298"
    key     = "prod/terraform.tfstate"
    region  = "ap-south-1"
  }
}
