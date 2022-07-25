<#

Finds nodes with matching domain in the caption and updates it to the hostname in all uppercase

#>
if ( -not $SwisConnection ) {
    $Hostname = "10.196.3.11"
    $SwisConnection = Connect-Swis -Hostname $Hostname -Credential ( Get-Credential -Message "Enter your Orion credentials for $Hostname" )
}

# We're putting this query in a here-string (multi-line format)
# I prefer it this way because it reads easier and spaces don't matter
$Query = @"
SELECT [Node].Caption
     , [Node].Uri AS [NodeUri]
     , [Node].CustomProperties.DomainName
     , [Node].CustomProperties.Uri AS [CPUri]
FROM Orion.Nodes AS [Node]
WHERE [Node].Caption LIKE '%.demo.lab'
ORDER BY [Node].Caption
"@

$NodesToUpdate = Get-SwisData -SwisConnection $SwisConnection -Query $Query

ForEach ( $Node in $NodesToUpdate ) {
    # Split the current caption along the domain (.) seperator
    $CaptionParts = $Node.Caption.Split('.')
    # Now we have an array of strings like:
    # 'win-582372-007', 'demo', 'local'

    # For the new caption, we only need the first part (the 0th element)
    # You access members of an array with square/hard brackets and the number of the element (0-based)
    $NewCaption = $CaptionParts[0]
    # We also need to make this uppercase - we do that with the .ToUpper method
    $NewCaption = $NewCaption.ToUpper()

    # The domain can be harder in forests where you have "something.dmz.demo.lab" and "dmz.demo.lab" is the desired domain
    # What we can do is take everything except the first part.
    # Since we need to reference the 'location' of the array, we need to know the number of elements in the array
    # We get that from the .Count property
    $CaptionPartsLength = $CaptionParts.Count
    
    # Now we need the caption parts starting at the second element (index = 1) through the end
    $DomainParts = $CaptionParts[1..$CaptionPartsLength]
    # Now we have only the parts we want ('dmz', 'demo', 'lab') in the correct order
    # These can be concatenated together with the -join operator
    $DomainName = $DomainParts -join '.'

    # For completeness, we probably want the domain in all lower, so we can do that with the .ToLower() method
    $DomainName = $DomainName.ToLower()
    Write-Host "Updating $( $Node.Caption ) to: $NewCaption / $DomainName"

    # Now we've got our parts and we just need to actually set them each.
    # Build the hashtable with the properties we've created.
    # We'll create two of them - one to update the node and another to update the custom property

    $PropertiesForNode = @{
        Caption = $NewCaption
    }

    $PropertiesForCP = @{
        DomainName = $DomainName
    }

    # Let's call the two Set-SwisObject commands (adding a little output for flair)
    Write-Host "Updating caption for $( $Node.Caption ) --> $NewCaption"
    Set-SwisObject -SwisConnection $SwisConnection -Uri $Node.NodeUri -Properties $PropertiesForNode

    Write-Host "Updating domain name CP for $( $Node.Caption ) --> $DomainName"
    Set-SwisObject -SwisConnection $SwisConnection -Uri $Node.CPUri -Properties $PropertiesForCP
}
