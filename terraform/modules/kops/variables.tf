variable "k8s_public_key" {
  description = "Kubernetes ssh public key"
  type        = "string"
}

variable "name" {
  description = "Name of this environment, may be used for labels or to namespace created resources"
}
