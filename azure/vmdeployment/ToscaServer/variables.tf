variable "location" {
  type        = string
  description = "The region to deploy to."
}

variable "tenantId" {
  type        = string
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
  description = "Value for the environment tag that will be applied to deployed resources."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for the VM."
}

variable "services_resource_group_name" {
  type        = string
  description = "Name of the Tricentis cloud services resource group."
}

variable "shared_image_gallery_name" {
  type        = string
  description = "The name of the shared image gallery containing the image to deploy."
}

variable "vm_prefix" {
  type        = string
  description = "Prefix used as base name for deployed resources. Note that the prefix needs to adhere to the guidelines for virtual machine names at https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftcompute"
}

variable "size" {
  type        = string
  default     = "Standard_D4s_v3"
  description = "The size of the Virtual Machine. Also see https://docs.microsoft.com/en-us/azure/virtual-machines/sizes."
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet the VM should be assigned to."
}

variable "installation_type" {
  type        = string
  default     = ""
  description = "Name of the tosca installation type to deploy. Can be ToscaServer, ToscaCommander, or DexAgent."

  validation {
    condition     = contains(["ToscaServer", "ToscaCommander", "DexAgent"], var.installation_type)
    error_message = "Valid values for var: installation_type are (ToscaServer, ToscaCommander, DexAgent)."
  }
}

variable "image_version" {
  type        = string
  default     = "latest"
  description = "Version of the image to deploy. Can be specified as 'latest' to obtain the latest version or 'recent' to obtain the most recently updated version."
}

variable "enable_automatic_updates" {
  type        = bool
  default     = true
  description = "Set to true if automatic updates should be enabled for the virtual machine."
}

variable "admin_password" {
  type        = string
  default     = "latest"
  description = "The password of the local administrator used for the virtual machine."
}
variable "admin_username" {
  type        = string
  sensitive   = true
  description = "The username of the local administrator used for the virtual machine."
}

variable "postdeploy_script_path" {
  type        = string
  description = "Path to the post-deployment script on the deployed VM, will be provided by DeployVM.ps1."
}

variable "database_fqdn" {
  type        = string
  description = "FQDN of the Tosca database."
}
