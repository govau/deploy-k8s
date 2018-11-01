output "name" {
  value = "${var.name}"
}

output "kops_cluster_state_bucket_id" {
  value = "${module.k_cld_kops.cluster_state_bucket_id}"
}

output "cld_subdomain_name_servers" {
  value = "${module.k_cld_kops.cld_subdomain_name_servers}"
}

data "aws_caller_identity" "current" {}

output "aws_account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}
