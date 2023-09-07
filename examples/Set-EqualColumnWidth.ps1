<#
Simple script to convert all columns on views (Classic Dashboards) to have the even widths

Author:  Kevin M. Sparenberg (https://thwack.solarwinds.com/members/kmsigma)
Version: 0.9
Last Updated: 2023-03-13
Validated: Orion Platform 2023.1

Shared on THWACK's Content Exchange: https://thwack.solarwinds.com/content-exchange/the-orion-platform/m/scripts/3719
#>


# Requirements:
# * SwisPowerShell Module v3.0+
#Requires -Module @{ ModuleName = 'SwisPowerShell'; ModuleVersion = '3.0.0' }

# This is where you define the pixel width of your display
#
$DisplayWidth = 1920 # pixels wide

# Build the connection to the SolarWinds Information Service
if ( -not ( $SwisConnection ) ) {
    $OrionServer = Read-Host -Prompt "Please enter the DNS name or IP Address for the Orion Server"
    $SwisCredentials = Get-Credential -Message "Enter your Orion credentials for $OrionServer"
    $SwisConnection = Connect-Swis -Credential $SwisCredentials -Hostname $OrionServer
}

# We only need a few things to calculate and change the column widths, so we'll only query for those things
$SwqlQuery = @"
SELECT ViewID        -- for output to screen
     , ViewTitle     -- for output to screen
     , Feature       -- used to alter some calculations
     , Columns       -- for the division
     , Column1Width  -- obvious
     , Column2Width  -- obvious
     , Column3Width  -- obvious
     , Column4Width  -- obvious
     , Column5Width  -- obvious
     , Column6Width  -- obvious
     , Uri           -- the 'key' for the Set-SwisObject
FROM Orion.Views
WHERE Columns <> 0
ORDER BY ViewID
"@

# Get all the views
$Views = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery

# We're going to extend the returned results with some additional information
################################################################################################

# First, we'll add a ScriptProperty to the objects that calculates the width for even columns
# There's a chance that we'll encounter a decimal during the division, so we're using the [math] library's Floor method.

# When working with Add-Member, you reference the 'parent' member as '$this'
$Views | Add-Member -MemberType ScriptProperty -Name 'EvenColumnWidth' -Value {
    # Math logic:
    # DisplayWidth
    # minus sidebar size (40px)
    # minus vertical scroll bar size (17px)
    # minus window border size (2px)
    # minus outside spacing for each column (16px)
    # minus 17 for rendering spacing around web objects

    # if the Feature is NTA, we need to account for the Flow Navigator and Flow Alerts as well. (32 px)
    $UsableWidth = $DisplayWidth - 40 - 17 - 2 - ( 16 * $this.Columns ) - 17
    if ( $this.Feature -eq 'NTA' ) {
        $UsableWidth -= 32
    }
    # Then divided by the number of columns
    [math]::Floor( $UsableWidth / $this.Columns )
} -Force

# We'll add a hashtable of the current values
# * This will be used for comparisons later
#
$Views | Add-Member -MemberType ScriptProperty -Name 'ColumnsOrig' -Value {
    [ordered]@{
        Columns      = $this.Columns
        Column1Width = $this.Column1Width
        Column2Width = $this.Column2Width
        Column3Width = $this.Column3Width
        Column4Width = $this.Column4Width
        Column5Width = $this.Column5Width
        Column6Width = $this.Column6Width
        # There is a max of 6 columns, so we'll stop there
    }
} -Force

# We'll also building a hashtable of the updated views
# * This is also used for comparison
# * It's also the argument sent to the Set-SwisObject cmdlet

# For PowerShell v7 or later, we'll use the ternary operator (https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.2#ternary-operator--if-true--if-false)
# It's basically a shorthand of "if (condition) { result1 } else { result2 }"
# The ternary operator is only available in PowerShell 7+
# 

if ( $PSVersionTable.PSVersion.Major -ge 7 ) {
    # PowerShell 7+ way
    $Views | Add-Member -MemberType ScriptProperty -Name 'ColumnsNew' -Value {
        [ordered]@{
            Columns      = $this.Columns;
            Column1Width = ( $this.Columns -ge 1 ) ? $this.EvenColumnWidth : 0 # New width when 1 or more columns
            Column2Width = ( $this.Columns -ge 2 ) ? $this.EvenColumnWidth : 0 # New width when 2 or more columns
            Column3Width = ( $this.Columns -ge 3 ) ? $this.EvenColumnWidth : 0 # New width when 3 or more columns
            Column4Width = ( $this.Columns -ge 4 ) ? $this.EvenColumnWidth : 0 # New width when 4 or more columns
            Column5Width = ( $this.Columns -ge 5 ) ? $this.EvenColumnWidth : 0 # New width when 5 or more columns
            Column6Width = ( $this.Columns -ge 6 ) ? $this.EvenColumnWidth : 0 # New width when 6 or more columns
            # There is a max of 6 columns, so we'll stop there
        }
    } -Force
}
else {
    # PowerShell 7- way
    $Views | Add-Member -MemberType ScriptProperty -Name 'ColumnsNew' -Value {
        [ordered]@{
            Columns      = $this.Columns;
            Column1Width = if ( $this.Columns -ge 1 ) { $this.EvenColumnWidth } else { 0 } # New width when 1 or more columns
            Column2Width = if ( $this.Columns -ge 2 ) { $this.EvenColumnWidth } else { 0 } # New width when 2 or more columns
            Column3Width = if ( $this.Columns -ge 3 ) { $this.EvenColumnWidth } else { 0 } # New width when 3 or more columns
            Column4Width = if ( $this.Columns -ge 4 ) { $this.EvenColumnWidth } else { 0 } # New width when 4 or more columns
            Column5Width = if ( $this.Columns -ge 5 ) { $this.EvenColumnWidth } else { 0 } # New width when 5 or more columns
            Column6Width = if ( $this.Columns -ge 6 ) { $this.EvenColumnWidth } else { 0 } # New width when 6 or more columns
            # There is a max of 6 columns, so we'll stop there
        }
    } -Force
}

# Lastly, we'll do the comparison.  This is complex, so I'll try to be detailed
# We'll turn each of the aforementioned hashtables into PowerShell Objects (needed for the Compare-Object cmdlet)
if ( $PSVersionTable.PSVersion.Major -ge 7 ) {
    # PowerShell 7+ way
    $Views | Add-Member -MemberType ScriptProperty -Name 'IsSame' -Value {
    ( Compare-Object -ReferenceObject (
            New-Object -TypeName PSObject -Property $this.ColumnsOrig # Converting the original sizes hashtable to a PowerShell Object
        ) -DifferenceObject (
            New-Object -TypeName PSObject -Property $this.ColumnsNew # Converting the new sizes hashtable to a PowerShell Object
            # below are the properties we'll want to compare
        ) -Property Columns, Colum1Width, Column2Width, Column3Width, Column4Width, Column5Width, Column6Width ) -eq $null ? $true : $false
        # If the response is null, then the objects are the same (return $true), otherwise they are different (return $false)
        # This uses the Ternary operator again
    } -Force
}
else {
    # PowerShell 7- way
    $Views | Add-Member -MemberType ScriptProperty -Name 'IsSame' -Value {
        if ( ( Compare-Object -ReferenceObject (
                    New-Object -TypeName PSObject -Property $this.ColumnsOrig # Converting the original sizes hashtable to a PowerShell Object
                ) -DifferenceObject (
                    New-Object -TypeName PSObject -Property $this.ColumnsNew # Converting the new sizes hashtable to a PowerShell Object
                    # below are the properties we'll want to compare
                ) -Property Columns, Colum1Width, Column2Width, Column3Width, Column4Width, Column5Width, Column6Width ) -eq $null ) { $true } else { $false }
        # If the response is null, then the objects are the same (return $true), otherwise they are different (return $false)
    } -Force
}

# Now we know which views need updates, because we can ask for views where IsSame is false.
# Then we can run a the update on each of those results

# We'll add a progress bar because systems can have hundreds of views
# I'm choosing to do this is a For loop instead of a ForEach, so I can use $i (the current index) as the progress
For ( $i = 0; $i -lt $Views.Count; $i++ ) {
    # Build the progress bar
    Write-Progress -Activity "Updating Views" -Status "Updating $( $Views[$i].ViewTitle )/[ViewID: $( $Views[$i].ViewID )" -PercentComplete ( ( $i / $Views.Count ) * 100)
    # Output what we're doing to the screen
    if ( -not ( $Views[$i].IsSame  ) ) {
        Write-Verbose -Message "$( $Views[$i].ViewTitle )/[ViewID: $( $Views[$i].ViewID )]: Updating $( $Views[$i].Columns ) column(s) to $( $Views[$i].EvenColumnWidth ) px each"
        # This is the command that actually does the work
        Set-SwisObject -SwisConnection $SwisConnection -Uri $Views[$i].Uri -Properties $Views[$i].ColumnsNew
    }
}
# Send the progress bar the -Completed parameter so it clears from the screen
Write-Progress -Activity "Updating Views" -Completed