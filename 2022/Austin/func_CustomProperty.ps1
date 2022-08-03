#region Top of Script

#requires -version 2
<#
.SYNOPSIS 
    Examples of Functions to Create and Update Custom Properties via Orion SDK

.DESCRIPTION 
    https://github.com/solarwinds/OrionSDK/wiki/Managing-Custom-Properties

.NOTES
    Version:        1.0
    Author:         ZackM (https://thwack.solarwinds.com/members/zackm)
    Creation Date:  March 21, 2018
    Purpose/Change: Initial Script development.

    Version:        1.1
    Author:         ZackM (https://thwack.solarwinds.com/members/zackm)
    Creation Date:  May 28, 2018
    Purpose/Change: Added Set-CustomPropertyValue Function
#>

#endregion

#####-----------------------------------------------------------------------------------------#####

#region Functions

# Create a function to connect to the SolarWinds Information Service (SWIS)
Function Set-SwisConnection {
    
    [ cmdletbinding() ]

    Param(
        [ Parameter( Mandatory = $true, HelpMessage = "What SolarWinds server are you connecting to (Hostname or IP)?" ) ] [ string ] $SolarWindsServer,
        [ Parameter( Mandatory = $true, HelpMessage = "Do you want to use the credentials from PowerShell (Trusted), or a new login (Explicit)?" ) ] [ ValidateSet( 'Trusted', 'Explicit' ) ] [ string ] $ConnectionType
    )

    # Import the SolarWinds PowerShell Module
    Import-Module SwisPowerShell

    # Connect to SWIS
    IF ( $ConnectionType -eq 'Trusted'  ) {

        $swis = Connect-Swis -Trusted -Hostname $SolarWindsServer
    
    }

    ELSE {
    
        $creds = Get-Credential -Message "Please provide a Domain or Local Login for SolarWinds"

        $swis = Connect-Swis -Credential $creds -Hostname $SolarWindsServer

    }

RETURN $swis

}

# Create a function to create a new Custom Property
Function New-CustomProperty {
    
    [ cmdletbinding() ]

    Param(
        [ Parameter( Mandatory = $true, HelpMessage = "Value from the Set-SwisConnection Function" ) ] [ object ] $SwisConnection,
        [ Parameter( Mandatory = $true, HelpMessage = "What Object Type is this custom property for?" ) ] [ ValidateSet( 'Alerts', 'Applications', 'Groups', 'Interfaces', 'Nodes', 'Reports', 'Volumes' ) ] [ string ] $PropertyType,
        [ Parameter( Mandatory = $true, HelpMessage = "What name would you like to give this custom property?" ) ] [ string[] ] $PropertyName,
        [ Parameter( Mandatory = $true, HelpMessage = "What description would you like to give this custom property?" ) ] [ string ] $Description,
        [ Parameter( Mandatory = $true, HelpMessage = "What data type should be used?" ) ] [ ValidateSet( 'string', 'integer', 'datetime', 'single', 'double', 'boolean' ) ] [ string ] $ValueType,
        [ Parameter( Mandatory = $false, HelpMessage = "OPTIONAL: What is the maximum size, if using a 'string' data type? (Max 4000)" ) ] [ ValidateRange( 0,4000 ) ] [ int ] $Size,
        [ Parameter( Mandatory = $false, HelpMessage = "OPTIONAL: What values would you like to set for the drop down?" ) ] [ string[] ] $DropDown
    )

# Example: New-CustomProperty -SwisConnection $swis -PropertyType "string" -PropertyName "array" -Description "string" -ValueType "string" -Size "optional integer" -DropDown "optional array" -Mandatory <adding this argument = $true> -Default "optional string"
    
    # Set the Custom Property Usages to all available options so you're not limited
    # IsForEntityDetail is required to utilize new popover options in Orion Platform 2018.2 (thwack.solarwinds.com/.../DOC-194255)
    $Usages = @{ 'IsForAlerting' = $true; 'IsForAssetInventory' = $true; 'IsForEntityDetail' = $true; 'IsForFiltering' = $true; 'IsForGrouping' = $true; 'IsForReporting' = $true }

    # Set the Entity Object to be used to create your Custom Property
    # Note these options are going to be based on the SolarWinds modules you have installed
    # The below options reflect NPM and SAM
        If( $PropertyType -eq "Alerts" ) {
            $Entity = "Orion.AlertConfigurationsCustomProperties"
        }
        If( $PropertyType -eq "Applications" ) {
            $Entity = "Orion.APM.ApplicationCustomProperties"
        }
        If( $PropertyType -eq "Groups" ) {
            $Entity = "Orion.GroupCustomProperties"
        }
        If( $PropertyType -eq "Interfaces" ) {
            $Entity = "Orion.NPM.InterfacesCustomProperties"
        }
        If( $PropertyType -eq "Nodes" ) {
            $Entity = "Orion.NodesCustomProperties"
        }
        If( $PropertyType -eq "Reports" ) {
            $Entity = "Orion.ReportsCustomProperties"
        }
        If( $PropertyType -eq "Volumes" ) {
            $Entity = "Orion.VolumesCustomProperties"
        }

    # Create the new custom properties
    Foreach( $n in $PropertyName ) {

        Invoke-SwisVerb $SwisConnection $Entity CreateCustomPropertyWithValues @( $n, $Description, $ValueType, $Size, $null, $null, $null, $null, $null, $null, $DropDown, $Usages )

        Write-Host "Creating Custom Property: $( $n ) for Entity Type: $( $Entity )" -ForegroundColor Yellow
    }
}

# Create a function to modify/set object values on existing Custom Property
# github.com/.../CRUD.SettingCustomProperty.ps1
# This could be enhanced in several ways, most notably by using Dynamic Parameters for the ID and Value entries based on the $NodeCP parameter
Function Set-CustomPropertyValue {

    [ cmdletbinding() ]

    Param (
        [ Parameter( Mandatory = $true, HelpMessage = "Value from the Set-SwisConnection Function" ) ] [ object ] $SwisConnection,
        [ Parameter( Mandatory = $true, HelpMessage = "Primary Polling Engine Name" ) ] [ string ] $PrimaryPoller,
        [ Parameter( Mandatory = $true, HelpMessage = "Custom Property Name" ) ] [ string ] $CustomProperty,
        [ Parameter( Mandatory = $true, HelpMessage = "Is this a NODE Custom Property?" ) ] [boolean] $NodeCP,
        [ Parameter( HelpMessage = "NodeID for Custom Property assignment, REQUIRED for Nodes/Applications/Interfaces/Volumes" ) ] [ int ] $NodeID,
        [ Parameter( ParameterSetName = 'AlertID' ) ] [ int ] $AlertID,
        [ Parameter( ParameterSetName = 'ReportID' ) ] [ int ] $ReportID,
        [ Parameter( ParameterSetName = 'ApplicationID' ) ] [ int ] $ApplicationID,
        [ Parameter( ParameterSetName = 'InterfaceID' ) ] [ int ] $InterfaceID,
        [ Parameter( ParameterSetName = 'VolumeID' ) ] [ int ] $VolumeID,
        [ Parameter( ParameterSetName = 'StringValue' ) ] [ string ] $StringValue,
        [ Parameter( ParameterSetName = 'IntegerValue' ) ] [ int ] $IntegerValue,
        [ Parameter( ParameterSetName = 'DateTimeValue' ) ] [ datetime ] $DateTimeValue,
        [ Parameter( ParameterSetName = 'SingleValue' ) ] [ single ] $SingleValue, #Float with 7 digits of precision
        [ Parameter( ParameterSetName = 'DoubleValue' ) ] [ double ] $DoubleValue, #Float with 15-16 digits of precision
        [ Parameter( ParameterSetName = 'BooleanValue' ) ] [ boolean ] $BooleanValue # $true|$false
    )

<# Examples:
    Node CP: Set-CustomPropertyValue -SwisConnection $swis -PrimaryPoller <> -CustomProperty <> -NodeCP $true -NodeID <> [ $StringValue|$IntegerValue|$DateTimeValue|$SingleValue|$DoubleValue|$BooleanValue ]
    Alert CP: Set-CustomPropertyValue -SwisConnection $swis -PrimaryPoller <> -CustomProperty <> -NodeCP $false -AlertID <> [ $StringValue|$IntegerValue|$DateTimeValue|$SingleValue|$DoubleValue|$BooleanValue ] 
    Report CP: Set-CustomPropertyValue -SwisConnection $swis -PrimaryPoller <> -CustomProperty <> -NodeCP $false -ReportID <> [ $StringValue|$IntegerValue|$DateTimeValue|$SingleValue|$DoubleValue|$BooleanValue ]
    Application CP: Set-CustomPropertyValue -SwisConnection $swis -PrimaryPoller <> -CustomProperty <> -NodeCP $false -NodeID <> -ApplicationID <> [ $StringValue|$IntegerValue|$DateTimeValue|$SingleValue|$DoubleValue|$BooleanValue ]
    Interface CP: Set-CustomPropertyValue -SwisConnection $swis -PrimaryPoller <> -CustomProperty <> -NodeCP $false -NodeID <> -InterfaceID <> [ $StringValue|$IntegerValue|$DateTimeValue|$SingleValue|$DoubleValue|$BooleanValue ]
    Volume CP: Set-CustomPropertyValue -SwisConnection $swis -PrimaryPoller <> -CustomProperty <> -NodeCP $false -NodeID <> -VolumeID <> [ $StringValue|$IntegerValue|$DateTimeValue|$SingleValue|$DoubleValue|$BooleanValue ]
#>

# Set your object URI
If ( $NodeCP -eq $true ) {
    $uri = 'swis://' + $PrimaryPoller + '/Orion/Orion.Nodes/NodeID=' + $NodeID + '/CustomProperties'
    Write-Host "Setting URI from Node Custom Property" -ForegroundColor Yellow
}
If ( $NodeCP -eq $false -and $AlertID ) {
    $uri = 'swis://' + $PrimaryPoller + 'Orion/Orion.AlertConfigurations/AlertID=' + $AlertID + '/CustomProperties'
    Write-Host "Setting URI from Alert Custom Property" -ForegroundColor Yellow
}
If ( $NodeCP -eq $false -and $ReportID ) {
    $uri = 'swis://' + $PrimaryPoller + 'Orion/Orion.Report/ReportID=' + $ReportID + '/CustomProperties'
    Write-Host "Setting URI from Report Custom Property" -ForegroundColor Yellow
}
If ( $NodeCP -eq $false -and $ApplicationID -and $NodeID ) {
    $uri = 'swis://' + $PrimaryPoller + '/Orion/Orion.Nodes/NodeID=' + $NodeID + '/Applications/ApplicationID=' + $ApplicationID + '/CustomProperties'
    Write-Host "Setting URI from Application Custom Property" -ForegroundColor Yellow
}
If ( $NodeCP -eq $false -and $InterfaceID -and $NodeID ) {
    $uri = 'swis://' + $PrimaryPoller + '/Orion/Orion.Nodes/NodeID=' + $NodeID + '/Interfaces/InterfaceID=' + $InterfaceID + '/CustomProperties'
    Write-Host "Setting URI from Interface Custom Property" -ForegroundColor Yellow
}
If ( $NodeCP -eq $false -and $VolumeID -and $NodeID ) {
    $uri = 'swis://' + $PrimaryPoller + '/Orion/Orion.Nodes/NodeID=' + $NodeID + '/Volumes/VolumeID=' + $VolumeID + '/CustomProperties'
    Write-Host "Setting URI from Volume Custom Property" -ForegroundColor Yellow
}
If ( $NodeCP -eq $false -and (!( $NodeID ) ) -and ( $ApplicationID -or $InterfaceID -or $VolumeID ) ) {
    Write-Warning "Missing NodeID Parameter for Application, Interface, or Volume Custom Property"
}
If ( $NodeCP -eq $true -and (!( $NodeID ) ) ) {
    Write-Warning "Missing NodeID Parameter for Node Custom Property"
}

# Set the Custom Property Value
If ( $StringValue ) {
    $cp = @{
        $CustomProperty=$StringValue
    }
    Write-Host "String Value = $( $cp.Values )" -ForegroundColor Yellow
}
If ( $IntegerValue ) {
    $cp = @{
        $CustomProperty=$IntegerValue
    }
    Write-Host "Integer Value = $( $cp.Values )" -ForegroundColor Yellow
}
If ( $DateTimeValue ) {
    $cp = @{
        $CustomProperty=$DateTimeValue
    }
    Write-Host "DateTime Value = $( $cp.Values )" -ForegroundColor Yellow
}
If ( $SingleValue ) {
    $cp = @{
        $CustomProperty=$SingleValue
    }
    Write-Host "Single Value = $( $cp.Values )" -ForegroundColor Yellow
}
If ( $DoubleValue ) {
    $cp = @{
        $CustomProperty=$DoubleValue
    }
    Write-Host "Double Value = $( $cp.Values )" -ForegroundColor Yellow
}
If ( $BooleanValue ) {
    $cp = @{
        $CustomProperty=$BooleanValue
    }
    Write-Host "Boolean Value = $( $cp.Values )" -ForegroundColor Yellow
}

# Set the Custom Property Value
Write-Host "Setting Custom Property '$( $CustomProperty )':`n    $( $uri )`n    $( $cp.Keys )`n    $( $cp.Values )" -ForegroundColor Yellow

Set-SwisObject -SwisConnection $SwisConnection -Uri $uri -Properties $cp 

}

#endregion Functions


#####-----------------------------------------------------------------------------------------#####

#region Variables

# Set the SolarWinds server to connect to
$hostname = Read-Host -Prompt "Which SolarWinds server would you like to connect to?"

# Create a Name for the Custom Properties you want to create
$nodeCP = 'dark_theme_is_life'

# CP Description
$description = 'Should this object be presented in a glorious #DarkTheme?'

# CP Value Type
$valueType = 'string'

# CP String Size (ignored for non-string Value Types)
$size = 4000

# CP Drop Down Values
$dropDown = New-Object string[] 4
    $dropDown[0] = 'Go Sign Up for a UX session!'
    $dropDown[1] = 'http://thwack.ux-group.sgizmo.com/s3/'
    $dropDown[2] = 'Dark Theme All The Things'
    $dropDown[3] = 'Kevin made me use 4 options...'

# Target NodeID
$nodeID = 10

$nodeCPString = 'Dark Theme All The Things'

#endregion Variables
