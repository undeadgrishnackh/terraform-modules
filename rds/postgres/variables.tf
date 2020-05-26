variable "name" { default = "db" }
variable "apply_immediately" { default = false }
variable "instance_class" { default = "db.t2.small " }
variable "allocated_storage" { default = 20 }
variable "username" { default = "admin" }
variable "password" { default = "" }
variable "iam_auth_enabled" { default = true }
variable "security_group_ids" {
  type = list
}
variable "subnet_ids" {
  type = list
}
variable "backup_retention_period" { default = 7 }
variable "deletion_protection" { default = true }
variable "cloudwatch_logs_exports" {
  type    = list
  default = []
}