#Requires -Module @{ ModuleName = 'SwisPowerShell'; ModuleVersion = '3.0.0' }

function Get-SwisNodeIds {
    [CmdletBinding(
        DefaultParameterSetName = 'All Nodes', 
        PositionalBinding = $true,
        HelpUri = 'https://thwack.com/orionsdk')]
    [OutputType([bool])]
    [Alias("Get-SwisNodeIds")]
    Param
    (
        # The connection to the SolarWinds Information Service
        [Parameter(
            Mandatory = $true, 
            Position = 0,
            ParameterSetName = 'All Nodes')]
        [Parameter(
            Mandatory = $true, 
            Position = 0,
            ParameterSetName = 'Nodes by ID')]
        [Parameter(
            Mandatory = $true, 
            Position = 0,
            ParameterSetName = 'Nodes by Uri')]
        [Parameter(
            Mandatory = $true, 
            Position = 0,
            ParameterSetName = 'Nodes by Caption')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Swis")] 
        [SolarWinds.InformationService.Contract2.InfoServiceProxy]$SwisConnection,

        # Id or Ids of the nodes to retrieve
        [Parameter(ParameterSetName = 'Nodes by ID')]
        [Alias('Id')]
        [int32[]]$NodeID,

        [Parameter(ParameterSetName = 'Nodes by Uri')]
        [Alias('Uri')]
        [string[]]$NodeUri,

        [Parameter(ParameterSetName = 'Nodes by Caption')]
        [SupportsWildcards()]
        [Alias('Caption')]
        [string[]]$NodeCaption
    )

    Begin {
        $BaseSwqlQuery = "SELECT [N].NodeID FROM Orion.Nodes AS [N]"
        switch ( $PSCmdlet.ParameterSetName ) {
            'All Nodes' { 
                # No Where Clause Changes
                $SwqlQuery = $BaseSwqlQuery
            }
            'Nodes by ID' {
                $SwqlQuery = $BaseSwqlQuery + " WHERE [N].NodeID IN ($( $NodeID -join ", " ))"
            }
            'Nodes by Uri' {
                $SwqlQuery = $BaseSwqlQuery + " WHERE [N].Uri IN ('$( $NodeUri -join "', '" )')"
            }
            'Nodes by Caption' {
                $CaptionClause = @()
                ForEach ( $nc in $NodeCaption ) {
                    $nc = $nc.Replace('*', '%').Replace('?', '_')
                    $CaptionClause += "( [N].Caption LIKE '$( $nc )' )"
                }
                $SwqlQuery = $BaseSwqlQuery + " WHERE " + ( $CaptionClause -join ' OR ' )
            }
        }
        Write-Verbose -Message "Base Query:         $BaseSwqlQuery"
        Write-Verbose -Message "Query with filters: $SwqlQuery"
    }
    Process {
        Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery
        
    }
    End {
        # nothing to be done here
    }
} 


function Set-SwisNodeUnmanaged {
    [CmdletBinding(
        DefaultParameterSetName = 'Absolute Dates', 
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        PositionalBinding = $true,
        HelpUri = 'https://thwack.com/orionsdk')]
    [Alias("Set-NodeUnmanaged")]
    Param
    (
        # The connection to the SolarWinds Information Service
        [Parameter(
            Mandatory = $true, 
            Position = 0,
            ParameterSetName = 'Absolute Dates')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Swis")] 
        [SolarWinds.InformationService.Contract2.InfoServiceProxy]$SwisConnection,

        # Id or Ids of the nodes to unmanage
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ParameterSetName = 'Absolute Dates')]
        [Alias('Id')]
        [ValidateNotNull]
        [ValidateNotNullOrEmpty]
        [int32[]]$NodeID,

        # Start Date of the unmanage (defaults to "now")
        [Parameter(
            Position = 2,
            ParameterSetName = 'Absolute Dates')]
        [Parameter(
            Position = 2,
            ParameterSetName = 'Relative Timespan')]
        [datetime]$StartTimeUtc = ( Get-Date ).ToUniversalTime(),

        # End Date of the unmanage (defaults to "now" + 1 day)
        [Parameter(
            Position = 3,    
            ParameterSetName = 'Absolute Dates')]
        [datetime]$EndTimeUtc = ( Get-Date ).ToUniversalTime().AddDays(1),

        [Parameter(
            Position = 3,
            ParameterSetName = 'Relative Timespan')]
        [timespan]$Timespan
    )

    Begin {
        if ( $StartTimeUtc -ge $EndTimeUtc ) {
            Write-Error -Message "The end time is before the start time.  Cannot complete." -RecommendedAction "Please re-rerun with appropriate dates"
            break
        }

        # Set the relative flag if we are using timespans and not absolute date/times        
        $RelativeFlag = ( $pscmdlet.ParameterSetName -eq 'Relative Timespan' )
        
        $BaseSwqlQuery = "SELECT [N].NodeID FROM Orion.Nodes AS [N]"
        $SwqlQuery = $BaseSwqlQuery + " WHERE [N].NodeID IN ($( $NodeID -join ", " ))"
        
        Write-Verbose -Message "Base Query:         $BaseSwqlQuery"
        Write-Verbose -Message "Query with filters: $SwqlQuery"
    }
    Process {
        ForEach ( $n in $NodeId ) {
            if ( $RelativeFlag ) {
                $EndTimeUtc = $StartTimeUtc.Add( $Timespan )
            }
            if ( $pscmdlet.ShouldProcess( "$( $SwisConnection.ChannelFactory.Endpoint.DnsSafeHost )", "Unmanage Node ID $($n) from $StartTimeUtc to $EndTimeUtc" ) ) {
                Write-Verbose -Message "Unmanaging Node ID: $n"
                Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName 'Orion.Nodes' -Verb 'Unmanage' -Arguments  @( "N:$n", $StartTimeUtc, $EndTimeUtc, $RelativeFlag )
            }
        }
        
    }
    End {
        # nothing to be done here
    }
} 