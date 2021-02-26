locals {
  tags = merge(var.extra_tags, {
    IaCDesigners = "oliver@sentianSE.com"
    StateManagement = "Terraform"
    Purpose = "Management of stack tfstate backends in s3"
  })
}

variable "stacks_map" {
  type = map(string)
  default = {}
  description = "Map of unique stack ID to its folder (absolute path)"
}

variable "extra_tags" {
  type = map(string)
  default = {}
}

variable "s3_bucket_force_destroy" {
  default = false
  description = "Whether this bucket can be destroyed"
}


