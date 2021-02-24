locals {
  tags = merge(var.extra_tags, {
    IaCDesigners = "oliver@sentianSE.com"
    StateManagement = "Terraform"
    Purpose = "Management of stack tfstate backends in s3"
  })

  stacks_info = {for name, region in var.stacks : format("%s-%s", name, region) => region}
}

variable "stacks" {
  type = map(string)
  default = {}
  description = "Map of stack names to the region hosted in"
}

variable "extra_tags" {
  type = map(string)
  default = {}
}

variable "s3_bucket_force_destroy" {
  default = false
  description = "Whether this bucket can be destroyed"
}


