[![Professional Services](https://img.shields.io/badge/Professional%20Services-supported-informational?style=for-the-badge)]()

## SQL Login Account Discovery

This script can be utilized for discoverying SQL Logins on given target machines as part of the Discovery feature in Secret Server. This script will search a given target server for any SQL Server instances and then scan each instance for SQL Logins.

> Note: It will exclude built-in SQL Logins that exists in some versions such as `##MS_PolicyEventProcessingLogin##`

## Prerequisite

### SQL Server

The dbatools module supports execution against all **supported** versions of SQL Server.

> Note: Support or use against older, unsupported versions of SQL Server is provided as-is.

### Modules

The script utilizes an open-source module to provide a cleaner script and processing. This will require installation of the module on your Secret Server web node(s) or Distributed Engine.

Under an elevated session on your server (web node or Distributed Engine) run the following command:

```powershell
# Updates Nuget and PowerShellGet
Install-PackageProvider -Name Nuget -MinimumVersion '2.8.5.201' -Force -Confirm:$false
Install-Module PowerShellGet -Force -Confirm:$false

# Install the dbatools module
Install-Module dbatools
```

Information on dbatools module can be found [here](https://dbatools.io). The specific commands utilized in the script are documented here as well as the comment-based help in each function (e.g. `Get-Help Get-DbaLogin`):

- [Find-DbaInstance](https://docs.dbatools.io/#Find-DbaInstance)
- [Connect-DbaInstance](https://docs.dbatools.io/#Connect-DbaInstance)
- [Get-DbaLogin](https://docs.dbatools.io/#Get-DbaLogin)

### Privileged Account

The scanner will require an account that has the needed permission to discovery SQL Logins on any SQL Server instance(s) discoverd on each target. The script provided supports utilizing a Windows Login (domain account) or SQL Login (e.g. the `sa` account). 

> The minimum permission required to find SQL Logins on a SQL Server instance is `ALTER ANY LOGIN`.

Alternatively the account used in your Discovery (e.g. Discovery Source configuration) or Distributed Engine (e..g PowerShell runas secret) can be utilized, if proper permission is assigned.

## Secret Server Configuration

### Create Script

1. Navigate to **Admin | Scripts**
1. Select **Create New Script** (_see table below_)
1. Select **OK**

#### Create New Script details

| Field | Value |
| ------------ | -------------------------------- |
| Name | SQL Login Discovery |
| Description | Discovery SQL Logins on the target machine |
| Category | Dependency |
| Script | Paste contents of the [Discovery_SqlLogin.ps1](Discovery_SqlLogin.ps1) |

### Create Discovery Scanner

1. Navigate to **Admin | Discovery | Extensible Discovery | Configure Discovery Scanners**
1. Navigate to the **Accounts** tab
1. Select **Create New Scanner** (_see table below_)
1. Selct **OK**

#### Create New Scanner details

| Field | Value |
| ------------ | -------------------------------- |
| Name | SQL Logins |
| Description | Discovery SQL Logins on SQL Server |
| Discovery Type | Find Local Accounts |
| Base Scanner | PowerShell Discovery |
| Input Template | Windows Computer |
| Output Template | SQL Local Account |
| Script | SQL Login Discovery |
| Script Arguments | `$target $[1]$Username $[1]$Password` |

### Create Source Account Scanner

1. Navigate to **Admin | Discovery | Edit Discovery Sources**
1. Navigate to the desired source
1. Navigate to the **Scanner Settings** tab
1. Under **Find Accounts** select **Add New Account Scanner**
1. Select the **SQL Logins** scanner created in the previous section
1. Under **Secret Credential** add necessay secret (_if Discovery or Distributed Engine account will not be utilized_)
1. Under **Advanced Settings** adjust the **Scanner Timeout (minutes)** value if necessary
1. Select **OK**

## Next Steps

Once the above configuration has been done you can trigger Discovery to scan your environment to find all the SQL Logins.
