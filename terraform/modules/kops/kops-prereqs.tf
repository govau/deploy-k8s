# Cluster State storage
# https://github.com/kubernetes/kops/blob/master/docs/aws.md#cluster-state-storage
resource "aws_s3_bucket" "cluster_state" {
  bucket_prefix = "${var.name}-kops-cluster-state-"

  acl = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_zone" "cld_subdomain" {
  name = "${var.name}.cld.gov.au."
}
