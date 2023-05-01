# requests is needed for the underlying web calls
import requests
# getpass is required for password input without displays
import getpass
# orion sdk is required for the client connectivity
from orionsdk import SwisClient

# main() is our main function to do the thing
def main():
    # these are the variables where we store your connection information
    hostName  = 'kmshcoppe01bv.kmsigma.local' # Put your server ip/hostname here

    # default is 120
    newPollInterval = 90
    
    # Build a connection to the server
    print("Enter the username and password for '" + hostName + "'")
    username = input("Username: ")
    password = getpass.getpass(prompt='Password: ')
    swis = SwisClient(hostName, username, password)
    
    # This is the query we are using for only Windows machines
    swqlQuery = """
SELECT [Interfaces].Node.Caption
     , [Interfaces].Name
     , [Interfaces].InterfaceAlias
     , [Interfaces].UnPluggable
     , [Interfaces].Uri
FROM Orion.NPM.Interfaces AS [Interfaces]
WHERE [Interfaces].UnPluggable = 'FALSE'
  AND [Interfaces].OperStatus = 2 --Indicates "down"
  AND [Interfaces].AdminStatus = 1 --Indicates "enabled"
  AND [Interfaces].TypeDescription = 'Ethernet'
  AND [Interfaces].Node.Vendor = 'Cisco'
  AND [Interfaces].InterfaceAlias LIKE '%UserPort%'
    """

    # let's run the query and store the results in a variable
    response = swis.query(swqlQuery)
    
    # convert the responses URI's to a single array
    uris = [node['Uri'] for node in response['results']]
    # do the update
    swis.bulkupdate(uris, UnPluggable = True)
# end of main 

# required to suppress SSL certificate warnings
requests.packages.urllib3.disable_warnings()

if __name__ == '__main__':
    main()