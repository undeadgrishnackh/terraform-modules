output "arn" {
  value = join("", aws_lambda_function.lambda_external.*.arn, aws_lambda_function.lambda_source_dir.*.arn)
}

output "version" {
  value = join("", aws_lambda_function.lambda_external.*.version, aws_lambda_function.lambda_source_dir.*.version)
}

output "function_name" {
  value = var.name
}

output "name" {
  value = var.name
}

output "iam_role_arn" {
  value = module.lambda_role.iam_role_arn
}