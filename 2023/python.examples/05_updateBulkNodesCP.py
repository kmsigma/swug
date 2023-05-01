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

    # default is null (empty)
    newCpCity = 'Austin'
    
    # Build a connection to the server
    print("Enter the username and password for '" + hostName + "'")
    username = input("Username: ")
    password = getpass.getpass(prompt='Password: ')
    swis = SwisClient(hostName, username, password)
    
    # This is the query we are using for only Windows machines
    swqlQuery = """
SELECT [Nodes].Caption
        , [Nodes].IPAddress
        , [Nodes].Uri
FROM Orion.Nodes AS [Nodes]
WHERE [Nodes].IPAddress LIKE '10.1.%.%'
    """

    # let's run the query and store the results in a variable
    response = swis.query(swqlQuery)
    
    # convert the responses URI's to a single array
    uris = [( node['Uri'] + "/CustomProperties" ) for node in response['results']]
    # do the update
    swis.bulkupdate(uris, City = newCpCity)
# end of main 

# required to suppress SSL certificate warnings
requests.packages.urllib3.disable_warnings()

if __name__ == '__main__':
    main()