module "vpc" {
  source = ""../../modules/aws-vpc"
  environment= "vault-consul"

  availability_zones = {
    us-east-1 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
}
