locals {
  tags = merge(var.extra_tags, {
    IaCDesigners = "oliver@sentianSE.com"
    StateManagement = "Terraform"
    Purpose = "Management of stack tfstate backends in s3"
  })

  this_stack_info = { "." = {stack_id="tfstate_backends", module_id="manager"} }
  stacks_map = merge(var.stacks_map, (
    var.this_tfstate_in_s3 ? local.this_stack_info : {}
  ))
}

variable "stacks_map" {
  type = map(object({
    stack_id = string,
    module_id = string
  }))
  default = {}
  description = "Map of folder (absolute path) to unique stack ID and module ID"
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

