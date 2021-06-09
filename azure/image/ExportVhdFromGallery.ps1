<#
.SYNOPSIS
    Extracts a deployable VHD from a image gallery image.
.NOTES
    Adapted from https://arsenvlad.medium.com/creating-vhd-azure-blob-sas-url-from-azure-managed-image-2be0e7c287f4
#>

$GalleryResourceGroup = "toscacloud8"
$GalleryName = "toscacloudgallery8" # Shared Image gallery containing images
$Location = "westeurope"
$ImageName = "ToscaServer"
$ImageVersion = "0.6.1"
$targetResourceGroup = "toscacloud8vhdexport"

$imageDefinition = az sig image-definition show --resource-group $GalleryResourceGroup --gallery-name $GalleryName --gallery-image-definition $ImageName | ConvertFrom-Json
$imageDefinitionVersion = az sig image-version show --resource-group $GalleryResourceGroup --gallery-name $GalleryName --gallery-image-definition $ImageName --gallery-image-version $ImageVersion | ConvertFrom-Json
Write-Output "Convert image $($imageDefinition.name) version $($imageDefinitionVersion.name) to vhd."

Write-Output "Create resource group $targetResourceGroup."
if((az group exists --name $targetResourceGroup) -eq "true"){
    az group delete --yes --name $targetResourceGroup
}

az group create --location $Location --name $targetResourceGroup --tags owner=team-bob purpose="Temporary Resource group used to generate tosca cloud deployment images."

$saName = "cloudimagesexport"
$containerName = "images"
Write-Output "Create storage account $saName for vhd."
az storage account create --resource-group $targetResourceGroup --name $saName --location $Location --sku Standard_LRS --kind StorageV2 --access-tier Hot
$saKeys = az storage account keys list --resource-group $targetResourceGroup --account-name $saName | ConvertFrom-Json
$key = $saKeys[0].value

az storage container create --resource-group $targetResourceGroup --account-name $saName --name $containerName --account-key $key

Write-Output "Export managed disk from image gallery."
$managedDisk = az disk create --resource-group $targetResourceGroup --location $Location --name "$ImageName$ImageVersion" --gallery-image-reference $imageDefinitionVersion.id
$managedDisk
$managedDisk = $managedDisk | ConvertFrom-Json

$imageSasUrl = (az disk grant-access --resource-group $targetResourceGroup --name $managedDisk.name --duration-in-seconds 36000 --access-level Read | ConvertFrom-Json).accessSas

Write-Output "Extract VHD from managed disk."
az storage blob copy start `
    --destination-blob "$($managedDisk.name).vhd" `
    --destination-container $containerName `
    --account-name $saName `
    --account-key $key `
    --source-uri "`"$imageSasUrl`""
    
Write-Output "Waiting for copy process to finish"
$copySuccess = $false
$waitTime = 2 * 60
for ($i = 0; $i -lt 150; $i++) {
    $copyStatus = az storage blob show --account-name $saName --container-name $containerName --name "$($managedDisk.name).vhd" --account-key $key | ConvertFrom-Json
    $copyStatus.properties.copy
    if($copyStatus.properties.copy.status -eq "success"){
        $i = 999
        $copySuccess = $true
    } else {
        Start-Sleep -Seconds $waitTime
    }
}
if($copySuccess -eq $false){
    Write-Error "An error occurred while exporting the managed disk."
    return
}

Write-Output "Completed"