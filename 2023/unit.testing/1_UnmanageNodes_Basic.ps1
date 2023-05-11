#region setup
clear-host
Import-Module .\2023\unit.testing\func_Base64String.psm1 -Force

Import-Module .\2023\unit.testing\func_ResetDemo.psm1 -Force

# Build the connection
if ( -not $SwisConnection ) {
    $ConnectionDetails = Get-Content -Path .\2023\unit.testing\SwisCreds.json | ConvertFrom-Json
    $SwisConnection = Connect-Swis -Hostname $ConnectionDetails.hostname -UserName $ConnectionDetails.username -Password ( $ConnectionDetails.encodedPassword | ConvertFrom-Base64String )
}

Reset-SwisDemo -SwisConnection $SwisConnection
#endregion setup

import-module .\2023\unit.testing\1_UnmanageNodes_Basic.psm1 -Force

Write-Host "Colecting Nodes"
$ids = Get-SwisNodeIds ($SwisConnection)

Write-Host "Unmanaging Nodes"
Set-SwisNodesUnmanagedById($ids) 