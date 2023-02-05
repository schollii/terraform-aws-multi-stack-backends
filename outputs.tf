output "iam_policy_multi_stack_backends_common" {
  value       = aws_iam_policy.multi_stack_backends_common.name
  description = "Policy needed to access any state/bucket managed by this manager"
}

output "iam_policy_multi_stack_backends_manager" {
  value       = one(aws_iam_policy.multi_stack_backends_manager[*].name)
  description = "Policy needed to access the state of this manager"
}

output "iam_policy_multi_stack_backends_stacks" {
  value       = [for p in aws_iam_policy.multi_stack_backends_stack : p.name]
  description = "Policy needed to access stack-specific state managed by this manager"
}

output "iam_policy_multi_stack_backends_modules" {
  value       = [for p in aws_iam_policy.multi_stack_backends_module : p.name]
  description = "Policy needed to access stack-module-specific state managed by this manager"
}

