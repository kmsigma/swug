# Get a list of NodeIDs, based on a custom property
$SwqlQuery = @"
SELECT [N].NodeID
     , [N].Caption
FROM Orion.Nodes AS [N]
WHERE [N].CustomProperties.NightlyUnmanage = 'True'
"@
$Nodes = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery

#set start and end time
$StartTime = (Get-Date).ToUniversalTime().AddMinutes(-1)
$EndTime = $StartTime.AddHours(6)

# cycle through IDs, and call invoke-swis to unmanage each one
ForEach ($Node in $Nodes) {
    
    Write-Host "Unmanaging $( $Node.Caption ) [ID: $( $Node.NodeID )] from $( $StartTime ) to $( $EndTime ): " -NoNewline
    $UnmanagedNode = Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName "Orion.Nodes" -Verb "Unmanage" -Arguments @( "N:$( $Node.NodeID )", $StartTime, $EndTime, $false )
    if ( $UnmanagedNode ) {
        Write-Host "Success!" -ForegroundColor Green
    }
    else {
        Write-Host "Failure!" -ForegroundColor Red
    }

}