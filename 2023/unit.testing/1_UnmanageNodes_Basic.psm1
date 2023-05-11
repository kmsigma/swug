
#function to return the node IDs and captions of nodes with the Custom Property "To Unmanage" set
function Get-SwisNodeIds ($SwisConnection) {
    $swql = "SELECT [N].NodeID FROM Orion.Nodes AS [N] WHERE [N].CustomProperties.NightlyUnmanage = 'True'"

    $results = Get-SwisData -SwisConnection $SwisConnection -query $swql
    $results
    
}

#basic function to unmanage nodes based on ID for one hour
function Set-SwisNodesUnmanagedById([int32[]]$ids) {
    $StartTime = (Get-Date).ToUniversalTime()
    $EndTime = (Get-Date).ToUniversalTime().AddHours(1)
    
    ForEach ($id in $ids) {
        
        Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName 'Orion.Nodes' -Verb 'Unmanage' -Arguments @("N:$Id", $StartTime, $EndTime, $false)  | Out-Null
    }
}