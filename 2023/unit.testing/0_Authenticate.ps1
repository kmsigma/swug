<#
Credential and Connection Testing
#>
#Requires -Module @{ ModuleName = 'SwisPowerShell'; ModuleVersion = '3.0.0' }

# Import some helper functions
Import-Module .\2023\unit.testing\func_Base64String.psm1 -Force
Import-Module .\2023\unit.testing\func_TestSwis.psm1 -Force
Import-Module .\2023\unit.testing\func_ResetDemo.psm1 -Force

# If the PowerShell Module isn't enabled but is installed, let's enable it
if ( -not ( Get-Module -Name 'SwisPowerShell' ) ) {
    Import-Module -Name 'SwisPowerShell' -MinimumVersion 3.0.0.0
}

# Build the connection
if ( -not $SwisConnection ) {
    $ConnectionDetails = Get-Content -Path .\2023\unit.testing\SwisCreds.json | ConvertFrom-Json
    $SwisConnection = Connect-Swis -Hostname $ConnectionDetails.hostname -UserName $ConnectionDetails.username -Password ( $ConnectionDetails.encodedPassword | ConvertFrom-Base64String )
}

# Test the connection
if ( Test-SwisConnection -SwisConnection $SwisConnection ) {
    Write-Host "We're connected to '$( $SwisConnection.ChannelFactory.Endpoint.ListenUri.DnsSafeHost )'"
}
else {
    Write-Error -Message "We're not connected to a SolarWinds Information Service Instance"
}