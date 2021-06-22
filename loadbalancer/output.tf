output "alb_arn" {
  # the definition of the variable is defined into the output.tf of the AWS provider
  # https://github.com/terraform-aws-modules/terraform-aws-alb/blob/8f72fe772b4f9152064b68e0ce3fffcae9a3fe68/outputs.tf
  # the tricky part consists into the LB as an array of LBs --> TEST: aws elbv2 describe-load-balancers
  description = "The ID and ARN of the load balancer we created."
  value       = "${aws_lb.app_loadbalancer.arn}"
  #aws_lb.lb_arn
}

output "alb_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "alb_target_group" {
  value = aws_lb_target_group.default.arn
}
