<#
.SYNOPSIS
   A CloudStack/CloudPlatform Templates Listing Scriptlet.
.DESCRIPTION
   List all Templates of a CloudStack Cloud.
.EXAMPLE
   CloudStackListTemplates.ps1 
#>
# Writer by Loic Lambiel (loic.lambiel@exoscale.ch)
# Inspired and adapted from existing scripts done by Jeff Moody (fifthecho@gmail.com)
#
# 2014/3/19  v1.0 created

Import-Module CloudStackClient
$parameters = Import-CloudStackConfig

if ($parameters -ne 1) {
	$cloud = New-CloudStack -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
        $job = Get-CloudStack -cloudStack $cloud -command listTemplates -options templatefilter="featured"
	$templates = $job.listtemplatesresponse

	foreach ($TEMPLATE in $templates.template) {
        $TEMPLATEID = $TEMPLATE.id
        $TEMPLATEDISPLAYTXT = $TEMPLATE.displaytext
		Write-Host("Template `"$TEMPLATEDISPLAYTXT`" ID: $TEMPLATEID")
	}
}
else {
	Write-Error "Please configure the $env:userprofile\cloud-settings.txt file"
}

