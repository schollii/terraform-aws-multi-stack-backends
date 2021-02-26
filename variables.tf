locals {
  tags = merge(var.extra_tags, {
    IaCDesigners = "oliver@sentianSE.com"
    StateManagement = "Terraform"
    Purpose = "Management of stack tfstate backends in s3"
  })
}

variable "stack_dirs" {
  type = list(string)
  default = []
  description = "List of stack folder, absolute"
}

variable "extra_tags" {
  type = map(string)
  default = {}
}

variable "s3_bucket_force_destroy" {
  default = false
  description = "Whether this bucket can be destroyed"
}


