output "vpc_id" {
  value = aws_vpc.main.id
}

output "pub_sub_ids" {
  value = aws_subnet.public.*.id
}

output "priv_sub_ids" {
  value = aws_subnet.private.*.id
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_arn" {
  value = data.aws_caller_identity.current.arn
}

output "aws_user_id" {
  value = data.aws_caller_identity.current.user_id
}
