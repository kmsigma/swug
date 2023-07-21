# requests is needed for the underlying web calls
import requests
# datetime provides the date operations and timedelta provides the addition/subtraction
from datetime import datetime, timedelta
# getpass is required for password input without displays
import getpass
# orion sdk is required for the client connectivity
from orionsdk import SwisClient

# main() is our main function to do the thing
def main():
    # these are the variables where we store your connection information
    hostName  = 'kmshcoppe01av.kmsigma.local' # Put your server ip/hostname here

    rightNow = datetime.utcnow()
    muteFrom = rightNow + timedelta(minutes=-1)
    muteUntil = muteFrom + timedelta(hours=2)

    # This is the query we are using
    swqlQuery = """
SELECT [Nodes].Caption
     , [Nodes].IPAddress
     , [Nodes].Uri
FROM Orion.Nodes AS [Nodes]
WHERE [Nodes].CustomProperties.City = 'St. Paul, MN'
    """

    # Build a connection to the server
    print("Enter the username and password for '" + hostName + "'")
    username = input("Username: ")
    password = getpass.getpass(prompt='Password: ')
    swis = SwisClient(hostName, username, password)
    
    # let's run the query and store the results in a variable
    response = swis.query(swqlQuery)
    
    # there are multiple responses, so we'll need to go through each entry
    print( "Muting " + str( len(response['results']) ) + " entities from " + muteFrom.isoformat() + " until " + muteUntil.isoformat() )

    uris = [( node['Uri'] ) for node in response['results']]

    # Arguments: entityUris, suppressFrom, suppressUntil
    swis.invoke('Orion.AlertSuppression', 'SuppressAlerts', uris, muteFrom, muteUntil)
        
requests.packages.urllib3.disable_warnings()

if __name__ == '__main__':
    main()