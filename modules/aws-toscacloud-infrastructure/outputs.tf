output "environment_name" {
  value = var.environment_name
}

# network
output "security_group_services_id" {
  value = aws_security_group.sg_services.id
}

output "security_group_clients_id" {
  value = aws_security_group.sg_clients.id
}

output "subnet_clients_id" {
  value = aws_subnet.subnet_clients.id
}

output "subnet_services_id" {
  value = aws_subnet.subnet_services.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

# S3
output "s3bucket_id" {
  value = aws_s3_bucket.s3.id
}

output "s3bucket_domain_name" {
  value = aws_s3_bucket.s3.bucket_domain_name
}

#rds
output "rds_id" {
  value = aws_db_instance.rds_db.id
}

output "rds_address" {
  value = aws_db_instance.rds_db.address
}

output "rds_identifier" {
  value = aws_db_instance.rds_db.identifier
}

output "rds_identifier_prefix" {
  value = aws_db_instance.rds_db.identifier_prefix
}

output "rds_port" {
  value = aws_db_instance.rds_db.port
}

# toscaserver ec2
output "toscaserver_id" {
  value = aws_instance.toscaserver.id
}

output "toscaserver_public_dns" {
  value = aws_eip.server_eip.public_dns
}

output "toscaserver_private_dns" {
  value = aws_eip.server_eip.private_dns
}

output "toscaserver_ami_id" {
  value = data.aws_ami.toscaserver_ami.id
}

output "toscaserver_ami_name" {
  value = data.aws_ami.toscaserver_ami.name
}
