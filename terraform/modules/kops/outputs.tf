output "name" {
  value = "${var.name}"
}

output "cluster_state_bucket_id" {
  value = "${aws_s3_bucket.cluster_state.id}"
}

output "cld_subdomain_zone_id" {
  value = "${aws_route53_zone.cld_subdomain.zone_id}"
}

output "cld_subdomain_name_servers" {
  value = "${aws_route53_zone.cld_subdomain.name_servers}"
}
