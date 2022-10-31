<#

Suppress alerts for all LOSA devices

#>
if ( -not $SwisConnection ) {
    $Hostname = "10.196.3.11"
    $SwisConnection = Connect-Swis -Hostname $Hostname -Credential ( Get-Credential -Message "Enter your Orion credentials for $Hostname" )
}


$NodesToMute = Get-SwisData -SwisConnection $SwisConnection -Query "SELECT Caption, Uri FROM Orion.Nodes WHERE IPAddress LIKE '10.149.%.%'"

# We are in the central time zone, right now, so those are reflected in the hand-typed entries below
$suppressFrom  = Get-Date "2022-11-05 12:00 AM" # 11 PM, Friday - Los Angeles Time
$suppressUntil = Get-Date "2022-11-06 04:00 PM" # 5 PM, Sunday  - Los Angeles Time
# Flip them to UTC
$suppressFrom = $suppressFrom.ToUniversalTime()
$suppressUntil = $suppressUntil.ToUniversalTime()

Invoke-SwisVerb -SwisConnection $SwisConnection -EntityName 'Orion.AlertSuppression' -Verb 'SuppressAlerts' -Arguments $NodesToMute.Uri , $suppressFrom, $suppressUntil



