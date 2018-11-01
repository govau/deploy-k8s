provider "aws" {
  version = "~> 1.33.0"
  region  = "ap-southeast-2"

  assume_role {
    role_arn     = "${var.aws_role_arn}"
    session_name = "Terraform"
    external_id  = "CloudTeam"
  }
}

provider "template" {
  version = "~> 1.0.0"
}
