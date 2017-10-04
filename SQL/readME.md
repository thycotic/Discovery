SQL Local Account Discovery
====================

The SQL Account Discovery doesn't require the creation of a machine scanner, or a Local Account Scan template. We can use the same SQL Local Account template for the Script.  
We will need to create a Local Accoutn Discovery Scanner, and point it to the SQL scan template


| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | Any Supported |
| PowerShell | Windows Management Framework 3+ |
| SQL Server | Any Supported |

**Note**: The Script should work on any supported SQL versions, but it's only been tested againsts SQL 2012 - 2014. 

**Configuration**

**Note: The Script doesn't require a new Scan Template created. It can use the existing SQL Scan Template.**

Step One:
====================
* Add the script to Secret Server in **Admin > Scripts** and test
* Navigate to **Admin >  Discovery > Extensible Discovery > Configure Discovery Scanners**
* Click on the **Local Accounts** tab snd  click **Create New**
* A popup window will appear, fill in the fields as follows:
    * **Name**: SQL Local Account
    * **Description**: SQL Server Local Account Scanner
    * **Discovery Type**: Find Local Accounts
    * **Base Scanner**: PowerShell
    * **Allow OU input**: Leave unchecked
    * **input template**: Windows Computer
    * **Output template**: SQL Local Account
    * **Script**: Select your Script
    * **Script Arguments**: $target

![Create New Scanner](imgs/scanner-1.png)

Step Two:
====================

* Navigate to **Discovery > Edit Discovery Sources > Select your Active Directory Source > Click on Scanner Settings Tab**
* Scroll to **Find Accounts** section and click **Add New Local Account Scanner**

![Create New Scanner](imgs/scanner-2.png)

* Add the Scanner we just created

![Create New Scanner](imgs/scanner-3.png)

* Click **Add Secret** and add your Privileged Account Secret

![Create New Scanner](imgs/scanner-5.png)

> Run Discovery again, and the new Scanner will start Discovering SQL Accounts
    
