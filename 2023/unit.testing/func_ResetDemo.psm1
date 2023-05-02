#Requires -Module @{ ModuleName = 'SwisPowerShell'; ModuleVersion = '3.0.0' }

function Reset-SwisDemo {
    [CmdletBinding(
        DefaultParameterSetName = 'Normal', 
        PositionalBinding = $true,
        HelpUri = 'https://thwack.com/orionsdk')]
    [OutputType([bool])]
    Param
    (
        # The connection to the SolarWinds Information Service
        [Parameter(
            Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0,
            ParameterSetName = 'Normal')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Swis")] 
        [SolarWinds.InformationService.Contract2.InfoServiceProxy]$SwisConnection
    )

    Begin {
        $SwqlQuery = "SELECT [N].NodeID FROM Orion.Nodes AS [N] WHERE [N].CustomProperties.NightlyUnmanage = 'TRUE' AND [N].Unmanaged = 'TRUE'"
        $NodeIDs = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery
    }
    Process {
        if ( $NodeIDs ) {
        ForEach ($Id in $NodeIDs) {
            Write-Verbose -Message "Remanaging Node $Id"
            Invoke-SwisVerb -SwisConnection $SwisConnection -Entity 'Orion.Nodes' -Verb 'Remanage' -Arguments @("N:$Id") | Out-Null
        } 
    
        ForEach ($Id in $NodeIDs) {
            Write-Verbose -Message "Polling Node $Id"
            Invoke-SwisVerb -SwisConnection $SwisConnection -Entity 'Orion.Nodes' -Verb 'PollNow' -Arguments @("N:$Id") | Out-Null
        }
    } else {
        Write-Verbose -Message "No matching nodes found"
    }

        
    }
    End {
        # nothing to be done here
    }
} 