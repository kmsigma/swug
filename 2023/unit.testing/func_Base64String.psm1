#region Base64 String Functions

# A few helper functions for encoding and decoding strings
# Note: Encoding via Base 64 is not, I repeat *NOT*, an acceptable way to encrypt data.  It's merely used here for portability.
#  One last time...
# Base64 encoding of strings is
#      N    N    OOOOO    TTTTTTT
#      NN   N   O     O      T
#      N N  N   O     O      T
#      N  N N   O     O      T
#      N   NN   O     O      T
#      N    N    OOOOO       T
#                     an acceptable way of making data secure.

<#
.Synopsis
    Encode a string to base 64 encoding
.DESCRIPTION
    This is used simply as an example of a way to obfuscate information.  Base64 encoding/decoding is NOT an acceptable way of encrypting content.  This is merely for demonstration purposes only.
.EXAMPLE
    ConvertTo-Base64String "Stuff&Junk"
    UwB0AHUAZgBmACYASgB1AG4AawA=
.EXAMPLE
    ConvertTo-Base64String "Stuff&Junk", "Garbage-Trash=Antique" 
    UwB0AHUAZgBmACYASgB1AG4AawA=
    RwBhAHIAYgBhAGcAZQAtAFQAcgBhAHMAaAA9AEEAbgB0AGkAcQB1AGUA
.EXAMPLE
    "Stuff&Junk" | ct64
    UwB0AHUAZgBmACYASgB1AG4AawA=

    In the above example, we are using pipeline input and the 'ct64' is an alias for the ConvertTo-Base64String function
#>
function ConvertTo-Base64String {
    [CmdletBinding()]
    [Alias("ct64")]
    [OutputType([string])]
    Param
    (
        # String or strings to encode
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [string[]]$String
    )

    Begin {
        # Nothing to be done here
    }
    Process {
        ForEach ( $s in $string ) {
            [Convert]::ToBase64String( [System.Text.Encoding]::Unicode.GetBytes($s) )
        }
        
    }
    End {
        # nothing to be done here
    }
} 
    


<#
.Synopsis
    Decode a string from base 64 encoding
.DESCRIPTION
    This is used simply as an example of a way to retrieve obfuscated information.  Base64 encoding/decoding is NOT an acceptable way of encrypting content.  This is merely for demonstration purposes only.
.EXAMPLE
    ConvertFrom-Base64String "UwB0AHUAZgBmACYASgB1AG4AawA="
    "Stuff&Junk"
.EXAMPLE
    ConvertFrom-Base64String "UwB0AHUAZgBmACYASgB1AG4AawA=", "RwBhAHIAYgBhAGcAZQAtAFQAcgBhAHMAaAA9AEEAbgB0AGkAcQB1AGUA"
    "Stuff&Junk"
    "Garbage-Trash=Antique" 
.EXAMPLE
    "UwB0AHUAZgBmACYASgB1AG4AawA=" | cf64
    Stuff&Junk

    In the above example, we are using pipeline input and the 'ct64' is an alias for the ConvertTo-Base64String function
#>
function ConvertFrom-Base64String {
    [CmdletBinding()]
    [Alias("cf64")]
    [OutputType([string])]
    Param
    (
        # String or strings to encode
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [string[]]$EncodedString
    )

    Begin {
        # Nothing to be done here
    }
    Process {
        ForEach ( $s in $EncodedString ) {
            [System.Text.Encoding]::Unicode.GetString( [Convert]::FromBase64String($s) )
        }
        
    }
    End {
        # nothing to be done here
    }
}
#endregion Base64 String Functions