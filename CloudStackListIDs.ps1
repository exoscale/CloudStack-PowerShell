<#
.SYNOPSIS
   A CloudStack/CloudPlatform Templates Listing Scriptlet.
.DESCRIPTION
   List Templates, service offering, zone and security group IDs of a CloudStack Cloud account.
.EXAMPLE
./CloudStackListIDs.ps1   
#>
# Writer by Loic Lambiel (loic.lambiel@exoscale.ch)
# Inspired and adapted from existing scripts done by Jeff Moody (fifthecho@gmail.com)
#
# 2014/3/20  v1.0 created

Import-Module CloudStackClient
$global:parameters = Import-CloudStackConfig

function ListIDS
{
        if ($parameters -ne 1) {
                ListTemplates
                ListZones
                ListSecGroups
                ListServiceOffering
        }
        else {
                Write-Error "Please configure the $env:userprofile\cloud-settings.txt file"
        }
}

function ListTemplates
{
        $cloud = New-CloudStack -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
        $job = Get-CloudStack -cloudStack $cloud -command listTemplates -options templatefilter="featured"
        $templates = $job.listtemplatesresponse

        Write-Host "Templates list:"
        foreach ($TEMPLATE in $templates.template) {
        $TEMPLATEID = $TEMPLATE.id
        $TEMPLATEDISPLAYTXT = $TEMPLATE.displaytext
                Write-Host("Template `"$TEMPLATEDISPLAYTXT`" ID: $TEMPLATEID")
        }
        Write-Host "************************************************"
}

function ListZones
{
        $cloud = New-CloudStack -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
        $job = Get-CloudStack -cloudStack $cloud -command listZones
        $zones = $job.listzonesresponse

        Write-Host "Zone list:"
        foreach ($ZONE in $zones.zone) {
        $ZONEID = $ZONE.id
        $ZONENAME = $ZONE.name
                Write-Host("Zone `"$ZONENAME`" is associated with Zone ID $ZONEID")
        }
        Write-Host "************************************************"
}

function ListSecGroups
{
        $cloud = New-CloudStack -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
        $job = Get-CloudStack -cloudStack $cloud -command listSecurityGroups
        $SecurityGroups = $job.listSecurityGroupsresponse

        Write-Host "Security groups list:"
        foreach ($SecurityGroup in $SecurityGroups.SecurityGroup) {
        $SecurityGroupID = $SecurityGroup.id
        $SecurityGroupNAME = $SecurityGroup.name
                Write-Host("Security Group `"$SecurityGroupNAME`" is associated with Security Group ID $SecurityGroupID ")
        } 
        Write-Host "************************************************"       
}

function ListServiceOffering
{
        $cloud = New-CloudStack -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
        $job = Get-CloudStack -cloudStack $cloud -command listServiceOfferings
        $serviceofferings = $job.listserviceofferingsresponse

        Write-Host "Service offering list:"
        foreach ($SERVICEOFFERING in $serviceofferings.serviceoffering) {
        $SERVICEOFFERINGID = $SERVICEOFFERING.id
        $SERVICEOFFERINGNAME = $SERVICEOFFERING.name
        $SERVICEOFFERINGDISPLAY = $SERVICEOFFERING.displaytext
                Write-Host("Service Offering `"$SERVICEOFFERINGNAME`" is associated with Service Offering ID $SERVICEOFFERINGID and has the parameters of $SERVICEOFFERINGDISPLAY")
        }
        Write-Host "************************************************"
}

#main script
ListIDS
