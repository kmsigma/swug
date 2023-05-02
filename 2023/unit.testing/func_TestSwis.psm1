#Requires -Module @{ ModuleName = 'SwisPowerShell'; ModuleVersion = '3.0.0' }
<#
.Synopsis
    Tests to see if your stored SolarWinds Information Service connection is valid
.Description
    Passes a simple query to the SolarWinds Information Service to determine if the connection is valid or not
.EXAMPLE
    $SwisConnection = Connect-Swis -Hostname 'mySolarWindsServer.domain.local' -UserName 'myUsername' -Password 'myC0mpl3xP@ssw0rd'
    PS > Test-SwisConnection -SwisConnection $SwisConnection
    True
.EXAMPLE
    $SwisConnection | Test-SwisConnection -Verbose
    VERBOSE: Query to Execute: SELECT [Diags].Name, [Diags].Value FROM System.Diagnostic AS [Diags] ORDER BY [Diags].Name
    VERBOSE: Executing Query against 'mySolarWindsServer.domain.local'
    VERBOSE: Query has returned 23 element(s): Returning $true
#>
function Test-SwisConnection {
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
        # The query we'll execute to see if the system is responding
        $SwqlQuery = "SELECT [Diags].Name, [Diags].Value FROM System.Diagnostic AS [Diags] ORDER BY [Diags].Name"
        Write-Verbose -Message "Query to Execute: $SwqlQuery"
    }
    Process {
        Write-Verbose -Message "Executing Query against '$( $SwisConnection.ChannelFactory.Endpoint.ListenUri.DnsSafeHost )'"
        $QueryResults = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery -ErrorAction SilentlyContinue
        # if the query has results, then return true, else return false
        if ( $QueryResults ) {
            Write-Verbose -Message "Query has returned $( $QueryResults.Count ) element(s): Returning `$true"
            $true
        }
        else {
            $false
        }
    
    }
    End {
        # same
    }
}