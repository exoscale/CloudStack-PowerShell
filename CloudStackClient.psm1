<#
.SYNOPSIS
   A CloudStack/CloudPlatform API client.
.DESCRIPTION
   A feature-rich Apache CloudStack/Citrix CloudPlatform API client for issuing commands to the Cloud Management system.
.PARAMETER command
   The command parameter is MANDATORY and specifies which command you are wanting to run against the API.
.PARAMETER options
   Optional command options that can be passed in to commands.

#>
# Writen by Jeff Moody (fifthecho@gmail.com)
# Based off code written by Takashi Kanai (anikundesu@gmail.com)
#
# 2011/9/16  v1.0 created
# 2013/5/13  v1.1 created to work with CloudPlatform 3.0.6 and migrated to entirely new codebase for maintainability and readability.
# 2013/5/17  v2.0 created to modularize everything.
# 2013/6/20  v2.1 created to add Powershell 2 support
# 2013/9/03  v2.5 created to add better error handling
# 2016/8/28  v2.6 Small refactor to fix signature mismatch in some cases. Powershell V3+ only supported (loic.lambiel@exoscale.ch)

[VOID][System.Reflection.Assembly]::Load("System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a");
$WebClient = New-Object net.WebClient

#$DebugPreference = "Continue"

function New-CloudStack{
    Param(
            [Parameter(Mandatory = $true)]
            [String] $apiEndpoint
        ,
            [Parameter(Mandatory = $true)]
            [String] $apiPublicKey
        ,
            [Parameter(Mandatory = $true)]
            [String] $apiSecretKey
        )
    $cloudStack = @()
    $cloudStack += $apiEndpoint
    $cloudStack += $apiPublicKey
    $cloudStack += $apiSecretKey
    return $cloudStack
}
Export-ModuleMember -Function New-CloudStack

function calculateSignature{
    Param(
        [Parameter(Mandatory=$true)]
        [String[]]
        $SECRET_KEY
    ,
        [Parameter(Mandatory=$true)]
        [String]
        $HASH_STRING
    )
    Write-Debug("Hash String:  $HASH_STRING")
    $HMAC_SHA1 = New-Object System.Security.Cryptography.HMACSHA1
    $HMAC_SHA1.key = [Text.Encoding]::ASCII.GetBytes($SECRET_KEY)
    $Digest = $HMAC_SHA1.ComputeHash([Text.Encoding]::ASCII.GetBytes($HASH_STRING))
    $Base64Digest = [System.Convert]::ToBase64String($Digest)  
    $signature = [System.Web.HttpUtility]::UrlEncode($Base64Digest)
    
    Write-Debug("Digest:       $Base64Digest")
    Write-Debug("Signature:    $signature")
    return $signature
}


function Get-CloudStack{
    Param(
        [Parameter(Mandatory=$true)]
        [String[]]
        $cloudStack
    ,
        [Parameter(Mandatory=$true)]
        [String]
        $command
    ,
        [String[]]
        $options
    )
    
    $ADDRESS = $cloudStack[0]
    Write-Debug ("Address: $ADDRESS")
    $API_KEY = $cloudStack[1]
    Write-Debug ("API_KEY: $API_KEY")
    $SECRET_KEY = $cloudStack[2]
    Write-Debug ("SECRET_KEY: $SECRET_KEY")
    Write-Debug ("Options: $options")
    #$optionString="apikey="+($API_KEY)+"&"+"command="+$command
    $optionString="apikey="+($API_KEY)
    $options += "command="+$command
    $options += "response=xml"
    $options = $options | Sort-Object
    Write-Debug ("Options sorted: $options")
    foreach($o in $options){
        $optionString += "&" + $o.split('=')[0] + "=" + ([System.Web.HttpUtility]::UrlEncode($o.split('=')[1]))
    }
    
    $optionString = $optionString -replace [Regex]::Escape("+"), "%20"

    $URL = $ADDRESS + "?" + $optionString

    Write-Debug("Pre-signed URL: $URL")
    Write-Debug("Option String: $optionString")
    $signature = calculateSignature -SECRET_KEY $SECRET_KEY -HASH_STRING $optionString.ToLower()
    $URL += "&signature="+$signature
    Write-Debug("URL: $URL")
    $Response = ""
    try {
       if ($psversiontable.psversion.Major -ge 3) {
            $Response = Invoke-RestMethod -Uri $URL -Method Get -ErrorAction Stop -ErrorVariable ErrorOut
            Write-Debug $Response
        }
        else {
            Write-Error "PowerShell V3 or later is required"
        }
    }
    catch{
        Write-Error "ERROR!"
        $errorType = $ErrorOut.GetType()
        if ($errorType.Name -eq "ArrayList") {
            Write-Error $ErrorOut[0]
        }
        else {
            Write-Error $ErrorOut
        }
        Write-Error "If this is unclear, please go to $URL in a browser for the API response."
    }
    Write-Debug "Response: $Response"
    return $Response
    
}

Export-ModuleMember -Function Get-CloudStack

function Import-CloudStackConfig{
    # Read configuration values for API Endpoint and keys
    $ChkFile = "$env:userprofile\cloud-settings.txt" 
    $FileExists = (Test-Path $ChkFile -PathType Leaf)

    If (!($FileExists)) 
    {
        Write-Error "Config file does not exist. Writing a basic config that you now need to customize."
        Write-Output "[general]`n" | Out-File $ChkFile
        Write-Output "Address=http://(your URL):8080/client/api`n" | Out-File -Append $ChkFile
        Write-Output "ApiKey=(Your API Key)`n" | Out-File -Append $ChkFile
        Write-Output "SecretKey=(Your Secret Key)" | Out-File -Append $ChkFile
        Return 1
    }
    ElseIf ($FileExists)
    {
        Get-Content "$env:userprofile\cloud-settings.txt" | foreach-object -begin {$h=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $h.Add($k[0], $k[1]) } }
        $ADDRESS=$h.Get_Item("Address")
        $API_KEY=$h.Get_Item("ApiKey")
        $SECRET_KEY=$h.Get_Item("SecretKey")
        Write-Debug "Address: $ADDRESS"
        Write-Debug "API Key: $API_KEY"
        Write-Debug "Secret Key: $SECRET_KEY"
        $config = @()
        $config += $ADDRESS
        $config += $API_KEY
        $config += $SECRET_KEY
        if (($ADDRESS -ne "http://(your URL:8080/client/api?") -and ($API_KEY -ne "(Your API Key)") -and ($SECRET_KEY -ne "(Your Secret Key)")) {
            return $config
        }
        else {
            Write-Error "Please configure the $env:userprofile\cloud-settings.txt file"
            return 1
        }
    }
}

Export-ModuleMember -Function Import-CloudstackConfig

function Get-CloudStackUserData{
    Param(
    [Parameter(Mandatory=$true)]
        [String]
        $userdata
    )
    Write-Debug "User Data: $userdata"
    $userdatab64 = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($userdata))
    Write-Debug "Base64 Encoded User Data: $userdatab64"
    $encodeduserdata = [System.Web.HttpUtility]::UrlEncode($userdatab64)
    return $encodeduserdata
}
Export-ModuleMember -Function Get-CloudStackUserData
