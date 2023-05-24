#region setup
clear-host
Import-Module .\2023\unit.testing\func_Base64String.psm1 -Force
Import-Module .\2023\unit.testing\1_UnmanageNodes_Basic.psm1 -Force
Import-Module -Name SwisPowerShell -Force

# Build the connection
if ( -not $SwisConnection ) {
    $ConnectionDetails = Get-Content -Path .\2023\unit.testing\SwisCreds.json | ConvertFrom-Json
    $SwisConnection = Connect-Swis -Hostname $ConnectionDetails.hostname -UserName $ConnectionDetails.username -Password ( $ConnectionDetails.encodedPassword | ConvertFrom-Base64String )
}


#endregion setup

Describe  'Get-SwisNodeIds' {
    Context "When called with default test system" {
        it "runs without error" {
            {
                Get-SwisNodeIds($SwisConnection)
            } | Should -Not -Throw
        }
        it "returns 19 nodeids" {
            $results = Get-SwisNodeIds($SwisConnection)
            $results.Count | should -be 19
        }
    }
    Context "When called no connection" {
        it "runs should throw an error" {
            {
                Get-SwisNodeIds($null)
            } | should -throw
        }
    }
}
   
Describe  'Set-SwisNodesUnmanagedById' {
    BeforeAll {
        [int32[]]$ids = '1010', '1012', '1013', '1022'
    }
    Context "When called with clean parameters" {
      
        it "runs without error for a single id" {
            {
                Set-SwisNodesUnmanagedById -swis $SwisConnection -ids 1022
            } | should -Not -throw
        }

        it "runs without error for multiple ids" {
            {
                Set-SwisNodesUnmanagedById -swis $SwisConnection -ids $ids
            } | should -Not -throw
        }
    }
}

