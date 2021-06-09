<#
.SYNOPSIS
    Copies an images between two shared image galleries
.NOTES
    Requires az cli to run
#>

Param(
    # Specifies service principal ID used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalId,

    # Specifies service principal secret used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalSecret,

    # Specifies the ID of a tenant used for azure resource deployment.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    # Specifies the name of the image gallery to copy from.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceGalleryName,

    # Specifies the name of the resource group of the source image gallery.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceRgName,

    # Specifies the name of the image definition to copy.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceImageName,

    # Specifies the version of the image to copy.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceImageVersion,

    # Specifies the name of the image gallery to copy to.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetGalleryName,
   
    # Specifies the name of the resource group of the target image gallery.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetRgName,

    # Specifies the name of the image definition to copy to in the target image gallery.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetImageName,

    # Specifies the version of the image to create in the target gallery.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetImageVersion
    
)

Write-Output "Creating new image version."
Write-Output "Source Gallery: $SourceRgName\$SourceGalleryName"
Write-Output "Source Image: $SourceImageName"
Write-Output "Source Version: $SourceImageVersion"
Write-Output "Target Gallery: $TargetRgName\$TargetGalleryName"
Write-Output "Target Image: $TargetImageName"
Write-Output "Target Version: $TargetImageVersion"

az login --service-principal -u $ServicePrincipalId -p $ServicePrincipalSecret --tenant $TenantId | ConvertFrom-Json

# Display warning and exit script if az cli is not logged in or not able to connect to subscription
az account show > $null
if($? -eq $false){
    return
}

try {
    Write-Output "Checking source gallery."
    $sourceDefinition = az sig image-definition list --resource-group $SourceRgName --gallery-name $SourceGalleryName 
        | ConvertFrom-Json 
        | Where-Object {$_.name -eq $SourceImageName }
    
    if($null -eq $sourceDefinition){
        throw "Source image definition $SourceImageName was not found in image gallery $SourceGalleryName."
    }
    
    $sourceImage = az sig image-version show `
        --resource-group $SourceRgName `
        --gallery-name $SourceGalleryName `
        --gallery-image-definition $SourceImageName `
        --gallery-image-version $SourceImageVersion 
        | ConvertFrom-Json
    
    if($null -eq $sourceImage){
        throw "Source image definition $SourceImageName does not contain image version $SourceImageVersion."
    }
}
catch {
    Write-Error "An error occurred while checking the source image gallery: $($_.Exception)" 
    az logout
    throw
}

try {
    Write-Output "Checking target gallery."
    $targetDefinition = az sig image-definition list --resource-group $TargetRgName --gallery-name $TargetGalleryName 
        | ConvertFrom-Json 
        | Where-Object {$_.name -eq $TargetImageName }
    
    if($null -eq $targetDefinition){
        throw "Target image definition $SourceImageName was not found in image gallery $TargetGalleryName."
    }
    
    $targetImage = az sig image-version list `
        --resource-group $TargetRgName `
        --gallery-name $TargetGalleryName `
        --gallery-image-definition $TargetImageName `
        | ConvertFrom-Json
        | Where-Object {$_.name -eq $TargetImageVersion }
    
    if($null -ne $targetImage){
        throw "Target image definition $SourceImageName already contains image version $TargetImageVersion."
    }
}
catch {
    Write-Error "An error occurred while checking the target image gallery: $($_.Exception)" 
    az logout
    throw
}

try {
    Write-Output "Creating new image version."
    az sig image-version create `
        --resource-group $TargetRgName `
        --gallery-name $TargetGalleryName `
        --gallery-image-definition $TargetImageName `
        --gallery-image-version $TargetImageVersion `
        --managed-image $sourceImage.id
}
catch {
    Write-Error "An error occurred while creating a new image version: $($_.Exception)" 
    throw
}
finally {
    az logout
}
