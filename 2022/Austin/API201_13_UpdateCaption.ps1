<#

Finds a node with 'WESTIIS01V' as the caption and updates it to 'WESTWEB01v'

#>
if ( -not $SwisConnection ) {
    $Hostname = "10.196.3.11"
    $SwisConnection = Connect-Swis -Hostname $Hostname -Credential ( Get-Credential -Message "Enter your Orion credentials for $Hostname" )
}

Get-SwisData -SwisConnection $SwisConnection -Query "SELECT Uri FROM Orion.Nodes WHERE Caption = 'WESTIIS01V'"

$Uri = Get-SwisData -SwisConnection $SwisConnection -Query "SELECT Uri FROM Orion.Nodes WHERE Caption = 'WESTIIS01V'"

$Properties = @{
    Caption = 'WESTWEB01v'
}

Set-SwisObject -SwisConnection $SwisConnection -Uri $Uri -Properties $Properties