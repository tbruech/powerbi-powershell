##############################
#.SYNOPSIS
# Gets the latest dotnet (core) SDK's netstandard.dll path.
#
#.DESCRIPTION
# Locates the latest dotnet SDK netstandrd.dll such as $SdkInstallDir\<version>\Microsoft\Microsoft.NET.Build.Extensions\net461\lib\netstandard.dll.
#
#.EXAMPLE
# PS:> .\GetNetstanardAssembly.ps1
# C:\Program Files\dotnet\sdk\2.1.202\Microsoft\Microsoft.NET.Build.Extensions\net461\lib\netstandard.dll 
# 
#
#.NOTES
# This script is designed from - https://github.com/PowerShell/PowerShell/blob/master/docs/cmdlet-example/command-line-simple-example.md#the-fix-for-missing-netstandarddll
##############################
[CmdletBinding()]
[OutputType([string])]
param
(
	# Path to SDK install directory
    [ValidateNotNullOrEmpty()]
    [string] $SdkInstallDir = ($IsLinux) ? '/usr/share/dotnet/sdk' : 'C:\Program Files\dotnet\sdk\',
	
	# The installed .NET SDK must have the same major and minor number and a lower build\patch number.
	[string] $MajorMinorSDKVersionCheck = '8.0.900'
)


$sdkVersions = Get-ChildItem -Path $SdkInstallDir -Directory | Where-Object Name -Match '\d+\.\d+\.\d+$' | ForEach-Object { 
    $version = [version]($_.BaseName.Split('-') | Select-Object -First 1)  # Remove any pre-release tags
    $_ | Add-Member -Name SDKVersion -MemberType NoteProperty -Value $version
    $_ 
}

if ($MajorMinorSDKVersionCheck) {
    Write-Verbose "Checking for SDK version less than: $MajorMinorSDKVersionCheck"
    $versionCheck = [version]$MajorMinorSDKVersionCheck
    $sdkDir = $sdkVersions | Where-Object { $_.SDKVersion.Major -eq $versionCheck.Major -and $_.SDKVersion.Minor -eq $versionCheck.Minor -and $_.SDKVersion.Build -lt $versionCheck.Build } | Sort-Object SDKVersion -Descending | Select-Object -First 1
    
    if(!$sdkDir) {
        throw "Unable to find SDK version (less than $MajorMinorSDKVersionCheck) under: $SdkInstallDir`nVersions available: $(($sdkVersions | % { $_.BaseName }) -join ', ' )"
    }
}
else {
    Write-Verbose "Checking for latest SDK version"
    $sdkDir = $sdkVersions | Sort-Object SDKVersion -Descending | Select-Object -First 1
}

if(!$sdkDir) {
	throw "Unable to find SDK version under: $SdkInstallDir"
}

Write-Verbose "Using SDK: $($sdkDir.FullName)"

$netStandardDllPath = Join-Path -Path $sdkDir.FullName -ChildPath 'Microsoft\Microsoft.NET.Build.Extensions\net461\lib\netstandard.dll'
if(Test-Path -Path $netStandardDllPath) {
    return $netStandardDllPath
}
else {
    throw "Unable to find netstandard assembly: $netStandardDllPath"
}