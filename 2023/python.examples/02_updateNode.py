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

    newCaption = 'My Home Printer'
    
    # This is the query we are using
    swqlQuery = """
SELECT [Nodes].Caption
     , [Nodes].IPAddress
     , [Nodes].Uri
FROM Orion.Nodes AS [Nodes]
WHERE [Nodes].Caption = 'hpm283fdw'
    """

    # Build a connection to the server
    print("Enter the username and password for '" + hostName + "'")
    username = input("Username: ")
    password = getpass.getpass(prompt='Password: ')
    swis = SwisClient(hostName, username, password)
    
    # let's run the query and store the results in a variable
    response = swis.query(swqlQuery)
    
    # there are multiple responses, so we'll need to go through each entry
    for result in response['results']:
        # output for a status
        print("Updating {Caption} @ {IPAddress} [{Uri}]'s Caption to '" + newCaption + "'".format(**result))
        # do the update
        swis.update(result['Uri'], Caption = newCaption)
# end of main 

# required to suppress SSL certificate warnings
requests.packages.urllib3.disable_warnings()

if __name__ == '__main__':
    main()