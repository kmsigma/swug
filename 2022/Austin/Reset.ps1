<#

Reset all changes from SWUG scripts

#>
if ( -not $SwisConnection ) {
    $Hostname = "10.196.3.11"
    $SwisConnection = Connect-Swis -Hostname $Hostname -Credential ( Get-Credential -Message "Enter your Orion credentials for $Hostname" )
}


$Uri = Get-SwisData -SwisConnection $SwisConnection -Query "SELECT Uri FROM Orion.Nodes WHERE NodeID = 154 AND Caption <> 'WESTIIS01V'"

$Properties = @{
    Caption = 'WESTIIS01V'
}

if ( $Uri ) {
    Set-SwisObject -SwisConnection $SwisConnection -Uri $Uri -Properties $Properties
}

$ResetCaptionDomainCP = @"
SELECT [Node].Caption
     , [Node].Uri AS [NodeUri]
     , [Node].CustomProperties.DomainName
     , [Node].CustomProperties.Uri AS [CPUri]
FROM Orion.Nodes AS [Node]
WHERE (
     IsNull([Node].CustomProperties.DomainName, '') = ''
  OR [Node].Caption NOT LIKE '%.demo.local'
  )
 AND [Node].ObjectSubType <> 'ICMP'

ORDER BY [Node].Caption
"@

$NodesToReset = Get-SwisData -SwisConnection $SwisConnection -Query $ResetCaptionDomainCP

ForEach ( $ResetNode in $NodesToReset ) {
    $NewCaption = ( $ResetNode.Caption.Split('.')[0] ).ToLower() + '.demo.lab'
    Write-Host "Updating $( $ResetNode.Caption ) to $NewCaption"
    Set-SwisObject -SwisConnection $SwisConnection -Uri $ResetNode.NodeUri -Properties @{
        'Caption' = $NewCaption
    }
    Set-SwisObject -SwisConnection $SwisConnection -Uri $ResetNode.CPUri -Properties @{
        'DomainName' = $null
    }
}

$MutedThingsQuery = @"
SELECT EntityUri AS [Uri]
     , SuppressFrom
     , SuppressUntil
FROM Orion.AlertSuppression
"@

$MutedThings = Get-SwisData -SwisConnection $SwisConnection -Query $MutedThingsQuery
ForEach ( $Thing in $MutedThings ) {
    Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName 'Orion.AlertSuppression' -Verb 'ResumeAlerts' -Arguments @( $MutedThings.Uri )
}
