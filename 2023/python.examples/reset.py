# requests is needed for the underlying web calls
import requests
# datetime provides the date operations and timedelta provides the add/subtraction
from datetime import datetime, timedelta
# getpass is required for password input without displays
import getpass
# orion sdk is required for the client connectivity
from orionsdk import SwisClient

# main() is our main function to do the thing
def main():
    # these are the variables where we store your connection information
    hostName  = 'kmshcoppe01av.kmsigma.local' # Put your server ip/hostname here

    # Build a connection to the server
    print("Enter the username and password for '" + hostName + "'")
    username = input("Username: ")
    password = getpass.getpass(prompt='Password: ')
    swis = SwisClient(hostName, username, password)

    # Commands
    # things to "undo"
    # rename [Nodes].NodeID = 4 to 'hpm283fdw'
    # set [Nodes].Vendor = 'Windows' pollinterval to 120
    # set [Nodes].CustomProperties.City to null or '' for everything
    # resumeAlerts for anything in the Orion.AlertSuppression table
    # set all currently "unpluggable" interfaces from true to false

    nodeId = '7'
    resetCaption = 'hpm283fdw'

    print("Phase 1: Renaming Node with ID " + nodeId + " to '" + resetCaption + "'")

    query1 = "SELECT Uri FROM Orion.Nodes WHERE NodeID = " + nodeId + " AND Caption <> '" + resetCaption + "'"

    response1 = swis.query(query1)
    for result in response1['results']:
        # print("{Uri}".format(**result))
        # Reset caption to 'hpm283fdw'
        swis.update(result['Uri'], Caption = resetCaption)

    print("Phase 1: Complete")


    print("Phase 2: Resetting Poll Interval to 120")

    query2 = """
SELECT Uri FROM Orion.Nodes WHERE Vendor = 'Windows' AND PollInterval <> 120
    """

    response2 = swis.query(query2)
    for result in response2['results']:
        #Set PollInterval to 120 (seconds)
        #print("{Uri}".format(**result))
        swis.update(result['Uri'], PollInterval = 120)

    print("Phase 2: Complete (" + str( len( result['Uri'] ) ) + " Nodes updated)")

    print("Phase 3: Nullifying Node Custom Property for 'City'")

    query3 = """
SELECT CONCAT([Nodes].Uri, '/CustomProperties') AS Uri
FROM Orion.Nodes AS [Nodes]
WHERE IsNull([Nodes].CustomProperties.City, '') <> ''
   OR [Nodes].CustomProperties.City IS NOT NULL
    """

    response3 = swis.query(query3)
    for result in response3['results']:
        # Set Node CP 'City' to null
        #print("{Uri}".format(**result))
        swis.update(result['Uri'], City = None)

    print("Phase 3: Complete (" + str( len( result['Uri'] ) ) + " Node Custom Properties updated)")

    print("Phase 4: Re-enabling alerts")

    query4 = """
SELECT [SuppressedAlerts].EntityUri AS [Uri]
FROM Orion.AlertSuppression AS [SuppressedAlerts]
JOIN System.ManagedEntity AS [Entities]
  ON [SuppressedAlerts].EntityUri = [Entities].Uri
WHERE [Entities].InstanceType = 'Orion.Nodes'
    """

    response4 = swis.query(query4)

    uris = [( node['Uri'] ) for node in response4['results']]
    swis.invoke('Orion.AlertSuppression', 'ResumeAlerts', uris)

    print("Phase 4: Complete (" + str( len( uris ) ) + " node alerts re-enabled)")

    print("Phase 5: Re-enabling alerts")

    query5 = """
SELECT [Interfaces].Uri
FROM Orion.NPM.Interfaces AS [Interfaces]
WHERE [Interfaces].Unpluggable = 'TRUE'
  AND [Interfaces].TypeDescription = 'Ethernet'
  AND [Interfaces].Node.Caption = 'KMS-UI-SWITCH'
  AND [Interfaces].Alias LIKE 'Port %'
    """

    response5 = swis.query(query5)
    for result in response5['results']:
        # set interfaces to NOT UnPluggable
        #print("{Uri}".format(**result))
        swis.update(result['Uri'], UnPluggable = False)

    print("Phase 5: Complete (" + str( len( result['Uri'] ) ) + " interfaces marked as NOT unpluggable)")

# Execution Begin
# ignore bad SSL certificates
requests.packages.urllib3.disable_warnings()

if __name__ == '__main__':
    main()