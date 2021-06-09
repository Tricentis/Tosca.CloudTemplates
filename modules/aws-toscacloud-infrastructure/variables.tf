variable "location" {
  type = string
  description = "The region to deploy to."
}

variable "environment_name" {
  type = string
  default = "ToscaCloudDeployment"
  description = "Value for the environment tag that will be applied to all deployed resources."
}

# RDS
variable "rds_instance_class" {
  type = string
  default = "db.t3.small"
  description = "The name of an instance class used for the database https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html."
}

variable "rds_administrator_username" {
  type = string
  sensitive = true
  description = "The username for the administrator account of the deployed RDS instance."
}

variable "rds_administrator_password" {
  type = string
  sensitive = true
  description = "The password for the administrator account of the deployed RDS instance."
}

variable "rds_port" {
  type = number
  default = 1433
  description = "The SQL connection port."
}

variable "rds_allocated_storage" {
  type = number
  default = 20
  description = "The amount of allocated storage in GiB."
}

variable "rds_backup_retention_period" {
  type = number
  default = 0
  description = "The number of days for which automated backups are retained."
}

variable "rds_backup_window" {
  type = string
  default = "03:30-04:30"
  description = "The daily time range during which automated backups are created if automated backups are enabled."
}

variable "rds_maintenance_window" {
  type = string
  default = "Mon:00:00-Mon:03:00"
  description = "The weekly time range during which system maintenance can occur, in Universal Coordinated Time."
}

# ToscaServer EC2
variable "toscaserver_instance_type" {
  type = string
  default = "t2.large"
  description = "Name of the instance type to use for the deployed instance of Tosca server."
}

variable "toscaserver_key_pair_name" {
  type = string
  description = "The name of the key pair to use for the deployed Tosca server instance."
}

variable "toscaserver_ami_version" {
  type = string
  default = "*"
  description = "Version of toscaserver to deploy."
}

variable "toscaserver_ami_owner" {
  type = string
  default = "416453364219" # Tricentis
  description = "Owner of the Tosca server ami."
}

variable "toscaserver_ami_name" {
  type = string
  default = "toscacloudtemplates_ToscaServer_*" 
  description = "Name of the Tosca server AMI."
}