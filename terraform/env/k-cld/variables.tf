variable "aws_role_arn" {
  description = "Role to assume when running terraform"
}

variable "name" {
  default     = "k"
  description = "Name of this environment, may be used for labels or to namespace created resources"
}
