# Oracle Local Account Discovery

The Oracle Account Discovery requires the creation of a Local Account Scan template. We can copy the  SQL Local Account template for the Script.  
We will need to create a Local Account Discovery Scanner, and point it to the Oracle Scan template.

## Assumptions

* Oracle is running on Linux
* PoshSSH is installed on Secret Server or Engine Servers
* A local linux account or LDAP bound account to authenticate to the oracle vms
* A local Oracle account with access to the oracle databases and permissions to read users
* Not all environments are the same, so certain tweaks might be required to make this work

| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | Any Supported |
| PowerShell | Windows Management Framework 3+ |
| Oracle  | Any Supported |

**Note**: The Script should work on any supported Oracle version, but it's only been tested against Oracle 11 and 12

## Configuration

### Step One

* Add the script to Secret Server in **Admin > Scripts** and test
* Install the PoshSSH PowerShell module on Secret Server and/or Engine servers
* Navigate to **Admin >  Discovery > Extensible Discovery > Configure Discovery Scanners**
* Click on the **Local Accounts** tab snd  click **Create New**
* A popup window will appear, fill in the fields as follows:
  * **Name**: Oracle Local Account
  * **Description**: Oracle Database Local Account Scanner
  * **Discovery Type**: Find Local Accounts
  * **Base Scanner**: PowerShell
  * **Allow OU input**: Leave unchecked
  * **input template**: Computer
  * **Output template**: Oracle Local Account
  * **Script**: Select your Script
  * **Script Arguments**: $[2]$USERNAME $[2]$PASSWORD $target $[3]$USERNAME $[3]$PASSWORD

### Step Two

* Navigate to **Discovery > Edit Discovery Sources > Select your *NIX* Source > Click on Scanner Settings Tab**
* Scroll to **Find Accounts** section and click **Add New Local Account Scanner**
* Add the Scanner we just created
* Click **Add Secret** and add the account to run PowerShell then add the linux local account Secret and then the oracle local account secret

#### For Oracle Discovery to work

download the ODP.NET driver in the project, or download the latest ODAC driver from [Oracle Downloads](http://www.oracle.com/technetwork/database/windows/downloads/index-090165.html)