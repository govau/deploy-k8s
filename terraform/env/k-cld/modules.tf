module "k_cld_kops" {
  source         = "../../modules/kops"
  name           = "${var.name}"
  k8s_public_key = "${file("k-cld-k8s-key.pub")}"
}
