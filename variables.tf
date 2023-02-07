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

variable "manager_tfstate_in_s3" {
  type        = bool
  description = "Whether this module's tfstate should be in s3"
  default     = false
}

variable "backends_bucket_name" {
  type        = string
  description = "Name of the tfstate backends bucket (must be unique across AWS region)"
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

variable "buckets_force_destroy" {
  type        = bool
  description = "Whether this bucket can be destroyed"
  default     = false
}

variable "create_tfstate_access_policies_for_stacks" {
  type        = bool
  description = "Whether to create the IAM policies for accessing the tfstates stored in backends bucket (for manual assignment to IAM users/roles/groups)"
  default     = false
}

variable "create_tfstate_access_policy_for_manager" {
  type        = bool
  description = "Whether to create the IAM policies for accessing the tfstates stored in backends bucket (for manual assignment to IAM users/roles/groups)"
  default     = false
}