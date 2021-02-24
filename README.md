This terraform module is to manage the bucket that will be used to store all 
the terraform state of all stacks and deployments in this account. 

Each stack has its own dynamoDB table to lock access to all tfstate 
files that belong to one stack. 

The module creates the backend.tf in each stack listed in the 
terraform.tfvars file. 

Stack in different regions can have the same name. Hence a stack's 
unique identifier is STACK_NAME-REGION. 