terraform {
  backend "s3" {
    bucket  = "gsharma1298"
    key     = "test/web-app/terraform.tfstate"
    region  = "ap-south-1"
  }
}
