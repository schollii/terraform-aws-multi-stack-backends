locals {
  tags = merge(var.extra_tags, {
    IaCDesigners = "oliver@sentianSE.com"
    StateManagement = "Terraform"
    Purpose = "Management of stack tfstate backends in s3"
  })

  stacks_map = merge(var.stacks_map, (
    var.this_tfstate_in_s3 ? { mono-s3-backends = "." } : {}
  ))
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

variable "this_tfstate_in_s3" {
  type = bool
  description = "Whether this module's tfstate should be in s3"
  default = false
}

