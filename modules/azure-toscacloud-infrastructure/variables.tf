variable "tenantId" {
  type        = string
  default     = "*"
  description = "Specifies the ID of the Azure tenant to deploy resources into."

}

variable "subscriptionId" {
  type        = string
  default     = ""
  description = "Specifies the ID of the Azure subscription to deploy resources into."
}

variable "environment_name" {
  type        = string
  default     = "ToscaCloudDeployment"
  description = "Value for the environment tag that will be applied to all deployed resources."
}

variable "location" {
  type        = string
  description = "Specifies the name of an Azure region to deploy resources into. Run `az account list-locations -o table` to list all available regions."
}

variable "resource_group_services_name" {
  type        = string
  default     = ""
  description = "The name of a resource group for tosca infrastructure VMs and services."
}

variable "resource_group_clients_name" {
  type        = string
  default     = ""
  description = "The name of a resource group for tosca client VMs."
}

variable "sql_server_name" {
  type        = string
  description = "The name of the database server."
}

variable "sql_server_admin_login" {
  type        = string
  sensitive   = true
  description = "The username for the SQL admin account."
}

variable "sql_server_admin_password" {
  type        = string
  sensitive   = true
  description = "The password for the SQL admin account."
}

variable "sql_sku" {
  type        = string
  default     = "GP_S_Gen5_2"
  description = "Name of the database SKU, see https://docs.microsoft.com/en-us/azure/azure-sql/database/resource-limits-vcore-single-databases or run `az sql db list-editions`"
}

variable "sql_max_size" {
  type        = number
  description = "The maximum database size in GB."
}

variable "sql_auto_pause_delay" {
  type        = number
  default     = -1
  description = "Time in minutes after which the databases are automatically paused if inactive. A value of -1 means that automatic pause is disabled. Also see https://docs.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview"
}

variable "sql_zone_redundant" {
  type        = bool
  default     = false
  description = "Whether or not the databases are zone redundant. Only settable for premium and business critical SKUs."
}

variable "tosca_database_name" {
  type        = string
  description = "The name of the database used by tosca."
}

variable "auth_database_name" {
  type        = string
  description = "The name of the database used by the authentication service."
}

variable "sql_private_endpoint" {
  type        = string
  default     = ""
  description = "The resource name of the SQL server private endpoint."
}

variable "sql_server_allow_network_access" {
  type        = bool
  default     = false
  description = "If set to true, public network access will be allowed on the sql server."
}

variable "virtual_network_name" {
  type        = string
  default     = ""
  description = "The name of a virtual network shared by all created resources."
}

variable "storage_account_name" {
  type        = string
  default     = ""
  description = "The name of a storage account used to support deployments."
}

variable "storage_account_allow_network_access" {
  type        = bool
  default     = false
  description = "If set to true, public network access will be allowed on the storage account."
}

variable "image_gallery_name" {
  type        = string
  default     = ""
  description = "The name of a Shared Image Gallery for Tosca cloud deployment images."
}
