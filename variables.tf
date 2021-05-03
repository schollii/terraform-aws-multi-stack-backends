locals {
  tags = merge(var.extra_tags, {
    IaCDesigners    = "oliver@sentianSE.com"
    StateManagement = "Terraform"
    Purpose         = "Management of tfstate backend of many stacks in s3"
  })

  // if manager specified, use it, but otherwise, it is the module's name with underscores
  // replaced by dash, except if module source is local then it is just manager
  module_path = path.module == "../../.." ? abspath(path.root) : replace(basename(path.module))
  manager_stack_id = (var.manager_stack_id == null ?
    replace(basename(local.module_path), "_", "-")
    : var.manager_stack_id
  )
}

variable "manager_stack_id" {
  type        = string
  description = "Override stack id for this root module (default: the module name)"
  default     = null
}

variable "manager_s3_key_prefix" {
  type        = string
  description = "Override default stack id for this root module"
  default     = "_manager_"
}

variable "backends_bucket_name" {
  type        = string
  description = "Override default name for the tfstates bucket"
  default     = "tfstate-s3-backends"
}

variable "backend_locks_table_name" {
  type        = string
  description = "Override default name for the tfstate locks table"
  default     = "tfstate-s3-backend-locks"
}

variable "stacks_map" {
  type = map(map(object({
    path = string,
  })))
  description = "Map of stack ID and module ID to their path on local system"
  default     = {}
}

variable "extra_tags" {
  type        = map(string)
  description = "Any additional tags beyond the default ones created by this module"
  default     = {}
}

variable "s3_bucket_force_destroy" {
  type        = bool
  description = "Whether this bucket can be destroyed"
  default     = false
}

variable "this_tfstate_in_s3" {
  type        = bool
  description = "Whether this module's tfstate should be in s3"
  default     = false
}

