output "policy_arn" {
  value       = aws_iam_policy.publisher.arn
  description = "ARN of a policy that was created"
}
