
#function to return the node IDs and captions of nodes with the Custom Property "To Unmanage" set
function Get-SwisNodeIds {
    [CmdletBinding()]
    param (
        #Swis Connection, from Connect-Swis
        [Parameter(Mandatory=$true)]
        $SwisConnection
    )
    
    begin {
        $swql = "SELECT [N].NodeID FROM Orion.Nodes AS [N] WHERE [N].CustomProperties.NightlyUnmanage = 'True'"
    }
    
    process {
        write-verbose "Calling $swql"
        $results = Get-SwisData -SwisConnection $SwisConnection -query $swql
    }
    
    end {
        Write-Verbose "Outputting results from Get-SwisNodeIds"
        Write-Output $results
    }
}


#basic function to unmanage nodes based on ID for one hour
function Set-SwisNodesUnmanagedById {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #Swis Connection, from Connect-Swis
        [Parameter(Mandatory=$true)]
        $SwisConnection,

        [Parameter(Mandatory=$true)]
        [int32[]]$ids,

        $StartTime = (Get-Date).ToUniversalTime(),
        $EndTime = (Get-Date).ToUniversalTime().AddHours(1)
    )
    
    begin {
        Write-Debug "Starttime : $starttime"
        Write-Debug "Endtime : $Endtime"
    }
    
    process {
        ForEach ($id in $ids){
            
            If ($PSCmdlet.ShouldProcess("$id","Unmanage Node")) {
                write-verbose "Unmanaging nodeid: $id"
                Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName 'Orion.Nodes' -Verb 'Unmanage' -Arguments @("N:$Id",$StartTime,$EndTime, $false)  | Out-Null
            }
        }
    }
       
}