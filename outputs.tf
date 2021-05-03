output "iam_policy_multi_stack_backends_common" {
  value = aws_iam_policy.multi_stack_backends_common
  description = "Policy needed to access any state/bucket managed by this manager"
}

output "iam_policy_multi_stack_backends_manager" {
  value = aws_iam_policy.multi_stack_backends_manager
  description = "Policy needed to access the state of this manager"
}

output "iam_policy_multi_stack_backends_stacks" {
  value = aws_iam_policy.multi_stack_backends_stack
  description = "Policy needed to access stack-specific state managed by this manager"
}

output "iam_policy_multi_stack_backends_modules" {
  value = aws_iam_policy.multi_stack_backends_module
  description = "Policy needed to access stack-module-specific state managed by this manager"
}

