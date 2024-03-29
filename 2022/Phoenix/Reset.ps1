<#

Reset all changes from SWUG scripts
Most Recent Updates: 02-AUG-2022

#>
if ( -not $SwisConnection ) {
    $Hostname = "10.196.3.11"
    $SwisConnection = Connect-Swis -Hostname $Hostname -Credential ( Get-Credential -Message "Enter your Orion credentials for $Hostname" )
}


$Uri = Get-SwisData -SwisConnection $SwisConnection -Query "SELECT Uri FROM Orion.Nodes WHERE NodeID = 154 AND Caption <> 'WESTIIS01V.demo.lab'"

$Properties = @{
    Caption = 'westiis01v.demo.lab'
}

if ( $Uri ) {
    Write-Host "Updating Caption on Node 154 to 'WESTIIS01V'" -NoNewline
    Set-SwisObject -SwisConnection $SwisConnection -Uri $Uri -Properties $Properties
    Write-Host " [COMPLETED]" -ForegroundColor Green
}
else {
    Write-Host "Don't need to update the Caption on Node 154" -ForegroundColor Yellow
}

$ResetCaptionDomainCP = @"
SELECT [Node].Caption
     , [Node].Uri AS [NodeUri]
     , [Node].CustomProperties.DomainName
     , [Node].CustomProperties.Uri AS [CPUri]
FROM Orion.Nodes AS [Node]
WHERE (
     IsNull([Node].CustomProperties.DomainName, '') <> ''
  OR [Node].Caption NOT LIKE '%.demo.lab'
  OR [Node].Caption NOT LIKE '%.dmz.lab'
  ) AND [Node].ObjectSubType IN ('SNMP', 'WMI', 'Agent')
ORDER BY [Node].Caption
"@

$NodesToReset = Get-SwisData -SwisConnection $SwisConnection -Query $ResetCaptionDomainCP

ForEach ( $ResetNode in $NodesToReset ) {
    $NewCaption = ( $ResetNode.Caption.Split('.')[0] ).ToLower() + '.demo.lab'
    $NewCaption = ( $ResetNode.Caption.Split('.')[0] ).ToLower() + '.' + $ResetNode.DomainName
    Write-Host "Updating $( $ResetNode.Caption ) to $NewCaption" -NoNewline
    Set-SwisObject -SwisConnection $SwisConnection -Uri $ResetNode.NodeUri -Properties @{
        'Caption' = $NewCaption
    }
    Set-SwisObject -SwisConnection $SwisConnection -Uri $ResetNode.CPUri -Properties @{
        'DomainName' = $null
    }
    Write-Host " [COMPLETED]" -ForegroundColor Green
}

# Remove Custom Property
try { 
    if ( Get-SwisData -SwisConnection $SwisConnection -Query 'SELECT DomainName FROM Orion.NodesCustomProperties' ) {
        Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName 'Orion.NodesCustomProperties' -Verb 'DeleteCustomProperty' -Arguments 'DomainName'
    }
}
catch {
    Write-Host "Node Custom Property 'DomainName' does not exist." -ForegroundColor Red
}


# Resetting Muted Devices

$MutedThingsQuery = @"
SELECT EntityUri AS [Uri]
     , SuppressFrom
     , SuppressUntil
FROM Orion.AlertSuppression
"@

$MutedThings = Get-SwisData -SwisConnection $SwisConnection -Query $MutedThingsQuery
<#
$EntityXml = '<ArrayOfstring xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/2003/10/Serialization/Arrays">'
$MutedThings | ForEach-Object { $EntityXml += "<string>$( $_.Uri )</string>" }
$EntityXml += '</ArrayOfstring>'
$EntityXml
#>

if ( $MutedThings ) {
    Write-Host "Unmuting $( $MutedThings.Count) entities"
    # Extract out the Uris of the muted devices:
    $Uris += $MutedThings | ForEach-Object { $_.Uri }
    Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName 'Orion.AlertSuppression' -Verb 'ResumeAlerts' -Arguments @( , $Uris )
    Write-Host " [COMPLETED]" -ForegroundColor Green


    $SuppressionState = Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName 'Orion.AlertSuppression' -Verb 'GetAlertSuppressionState' -Arguments @( , $Uris )
    $SuppressionState.EntityAlertSuppressionState | Select-Object EntityUri, SuppressionMode
}
else {
    Write-Host "Nothing is currently muted" -ForegroundColor Red
}