locals {
  tags = merge(var.extra_tags, {
    IaCDesigners = "oliver@sentianSE.com"
    StateManagement = "Terraform"
    Purpose = "Management of tfstate backend of many stacks in s3"
  })

  stacks_map = var.stacks_map
  manager_stack_id = var.manager_stack_id == null ? replace(basename(path.module), "_", "-") : var.manager_stack_id
}

variable "manager_stack_id" {
  type = string
  description = "Override stack id for this root module (default: the module name)"
  default = null
}

variable "manager_s3_key_prefix" {
  type = string
  description = "Override default stack id for this root module"
  default = "_manager_"
}

variable "backends_bucket_name" {
  type = string
  description = "Override default name for mono-bucket"
  default = "tfstate-s3-backends"
}

variable "stacks_map" {
  type = map(object({
    stack_id = string,
    module_id = string
  }))
  description = "Map of folder (absolute path) to unique stack ID and module ID"
  default = {}
}

variable "extra_tags" {
  type = map(string)
  description = "Any additional tags beyond the default ones created by this module"
  default = {}
}

variable "s3_bucket_force_destroy" {
  type = bool
  description = "Whether this bucket can be destroyed"
  default = false
}

variable "this_tfstate_in_s3" {
  type = bool
  description = "Whether this module's tfstate should be in s3"
  default = false
}

