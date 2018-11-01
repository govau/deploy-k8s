terraform {
  backend "s3" {
    key            = "k-cld"
    encrypt        = true
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-locks"

    # The following settings come from `-backend-config`
    # (e.g. use terraform init -backend-config=../secret-backend.cfg)
    # bucket =
    # kms_key_id =
  }
}
