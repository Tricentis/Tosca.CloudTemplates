# Tricentis Tosca Cloud Templates
## Introduction
Tosca cloud templates are a set of blueprints, templates and guides to build a self contained environment hosted by your cloud provider. The environment contains all basic infrastructure and VM images needed to deploy and run Tosca.

![Infrastructure overview](/readme/azure-overview.png "Infrastructure overview")

The templates are designed to be highly configurable and easily extendable. All parts of the end to end workflow can be edited and customized or exchanged to use as much or little as desired.

## Deployment Overview
A Tosca cloud environment is deployed in three phases
### Infrastructure deployment
The first phase deploys infrastructure resources and shared components.
### Image creation
After the needed infrastructure was created, tosca server and client VM images need to be created. The images are created via packer script which will bootstrap a new Azure vm, install all needed prerequisites and applications, capture a VM image and store it in an image gallery.
### VM deployment
Once the needed images for Tosca and Tosca server have been created, they can be used to deploy as many Tosca/Dex/Server VMs as needed.

# Infrastructure Deployment
## Overview
The infrastructure deployment phase ensures that shared components and static resources used by all subsequent steps are created and configured.

The script will allocate all resources in two resource groups
- A client resource groups for Tosca Commander and Dex agent VMs
- A services resource goup for Tosca Server and infrastructure resources

In addition to several supporting resources, the services resource group will contain the following major components:
- Azure SQL Server
- Virtual network
- Storage account
- Shared image gallery

Note that the client resource group will not contain any resources at this point.

## Prerequisites
- Prepare a host that will will bootstrap the environment with the following items installed 
    - [Azure CLI|https://docs.microsoft.com/en-us/cli/azure/install-azure-cli]
    - [The SQLServer module for PowerShell|https://www.powershellgallery.com/packages/SqlServer]
    - [Packer|https://www.packer.io/]
    - [Terraform|https://www.terraform.io/]
    - The [windows update provisioner for packer|https://github.com/rgl/packer-provisioner-windows-update]
- It is recommended to use an Azure vm as deployment host.

- Create an Azure service principal which will be used to create resources during the deployment. The principal needs to have the contributor or owner role on subscription level.

To limit the permissions needed for the service principal, it is also possible to scope its roles to individual resource groups. To do so please manually create two resource groups:
- A resource group which will later contain service resources like database, virtual network, etc.
- A resource group for client VMs
The service principal needs to have contributor or owner rights on both resource group to be able to deploy and configure resources.

## Deployment
### Parameters
Open the infrastructure deployment parameters file /azure/infrastructure/env/terraform.tfvars  and update it according to your environment. See /azure/infrastructure/variables.tf for a full list of available parameters and their descriptions.

We recommend Database size `GP_S_Gen5_2` when setting up a new environment which should be fine for most small to medium workloads, but you might need to scale the database depending on your use case and space requirements, also see https://azure.microsoft.com/en-us/pricing/details/sql-database/.

### Deployment script
Once all parameters have been set, run /azure/infrastructure/DeployInfrastructure.ps1. To get a list of all available and needed parameters, as well as usage syntax run `Get-Help .\DeployInfrastructure.ps1 -Detailed`

The script will perform several checks to make sure that all needed files and permission roles are available and deploy the terraform template in /azure/infastructure. After all items have been created, the script will run some additional steps to ensure that configurations and settings for later steps are present.
Once all deployment steps have been completed, the script will output several details about the environment, these should be noted down for the next steps.

# Image creation
## Overview
In the image creation phase, static VM images are created via packer build. There are 3 default image types:
- Windows server 2016 image with Tosca server
- Windows 10 with Tosca commander
- Windows 10 with a dex agent

The images are created with packer. Once created, the images are uploaded to an [image gallery|https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries] and can be deployed as new virtual machines as often as needed. Note that it is recommended to build all images before proceeding to the third stage.

## Prerequisites
Make sure that the infrastructure has been deployed and prepare the setup executables for Tricentis Tosca, Tosca server, and (if available) Tosca server patch that will be installed on the server and client VMs.

## Deployment
### Parameters
No parameters file is used in this phase.

### Deployment script
#### Setup upload
To make the Tosca setups available to the packer build, the setup executables need to be uploaded to the storage account that was deployed in the previous phase. To do so, run /azure/image/UploadSetup.ps1. To get a list of all available script parameters, as well as usage syntax, run `Get-Help .\UploadSetup.ps1 -Detailed`

After the upload process, the script will provide the path of all uploaded executables, these should be noted down for the next step. Note that the ToscaServerPatchPath can be safely omitted if no patch is available for the current Tosca server version.

#### Packer template
Once all setups are uploaded to the storage account, run /azure/image/CreateImage.ps1 to create the needed vm images. To get a list of all available script parameters, as well as usage syntax, run `Get-Help .\CreateImage.ps1 -Detailed`

The parameters ToscaSetupType and BuilderScriptPath should both point to a matching setup type:

| ToscaSetupType | BuilderScriptPath |
| --- | --- |
| ToscaCommander | /shared/image/packer-tosca-win10.json |
| DexAgent | /shared/image/packer-tosca-win10.json |
| ToscaServer | /shared/image/packer-server-winserver2016.json |

The script will perform several checks to make sure that all needed files and permission roles are available, and make sure that the image gallery is correctly configured. Once the validations have been completed, the script will create a firewall exceptions on the vnet for the public IP of the host running the script and generate shared access signatures on the storage account to make the uploaded setups available to the packer template.

The script will then kick off a packer build which will spin up a new VM, install all needed prerequisites and applications for the current image, generalize the VM, extract an image, and upload it to the shared image gallery. Once the packer build has been completed, the built image can be used to deploy Azure VMs. The end to end image creation process can take between 90 and 120 minutes.

Please note that the image creation script needs to be executed separately for each needed image.

# VM Deployment
## Overview
Once all needed VM images have been built, VMs are ready to be deployed from the image gallery. The deployments can be handled via regular azure means as any other image like individual deployments using arm templates or scale sets. Please see the steps below for an example deployment.  

## Prerequisites
Make sure that the basic infrastructure has been deployed and all VM images have been built.

## Deployment
### Parameters
Open the vm deployment parameter files in /azure/vmdeployment/[Deployment Type] and update thenm according to your environment:
Deployment | Parameter file
--- | ---
Tosca server | /azure/vmdeployment/ToscaServer/env/terraform.tfvars
Tosca commander | /azure/vmdeployment/Tosca/env/ToscaCommander/terraform.tfvars
Dex agent | /azure/vmdeployment/Tosca/env/DexAgent/terraform.tfvars

See /azure/vmdeployment/variables.tf for a full list of available parameters and their descriptions.

We recommend VM size Standard D4s V3 which should be fine for most general workloads, but you might need to adapt the VM size according to your use case and cost limitations, also see https://docs.microsoft.com/en-us/azure/virtual-machines/sizes.

### Deployment script
Once the parameter file has been prepared, run /azure/vmdeployment/DeployVM.ps1. To get a list of all available script parameters, as well as usage syntax, run `Get-Help .\DeployVM.ps1 -Detailed`

The script will perform several checks to make sure that all needed objects are available and start the deployment of the new VM according to the parameter file. Once the script is finished, it will output several details about the deployed VM.

# Further steps
Once all needed VMs have been deployed, the environment is ready to use. Common next steps include the configuration of tosca server and adapting the infrastructure to match your use case.

Please note that, for security reasons, incoming traffic has been blocked on both security groups, in order to access the VMs you will need to configure the security groups accordingly.