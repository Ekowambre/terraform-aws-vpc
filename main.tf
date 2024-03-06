module "vpc" {
  source = "./modules/networking"
}

data "aws_caller_identity" "current" {}

