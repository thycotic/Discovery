## SQL Login Account Discovery

This script can be utilized for discovering SQL Logins on a target machine as part of Discovery in Secret Server. The script provided will search a server for any SQL Server installations, attempt to connect to each found, and then pull the SQL Logins.

> Note: It will **exclude** built-in SQL Logins that exists in some versions such as `##MS_PolicyEventProcessingLogin##`

## Prerequisite

### SQL Server

The dbatools module supports execution against SQL Server 2005 and later versions.

### Modules

The script utilizes an open-source module to provide a cleaner script and processing. The module needs to be installed on your Secret Server web node(s) or Distributed Engine.

Under an elevated session on your server (web node or Distributed Engine), run the following command:

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

The script as-is supports using a privileged account to login to SQL Server to find logins. The account used to run Discovery will be utilized for scanning the target machine for SQL Server installations.

The account required for the scanner will be based on your use case and environment configuration. At a minimum, the scanner needs an account with rights to access SQL Server to pull logins. You can use a Windows or SQL Login account.

If two privileged accounts are required: to scan the server and a second to scan SQL Server for logins. Then code adjustment will be required. The account for scanning the server will be provided to `Find-DbaInstance`. The second account will be provided to `Connect-DbaInstance`.

### SQL Server Minimum Permission

The minimum permission required to find SQL Logins on a SQL Server instance is `ALTER ANY LOGIN`.

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
| Script | Paste contents of the desired script [Discovery_SqlLogin_All.ps1](Discovery_SqlLogin_All.ps1) or [Discovery_SqlLogin_PrivOnly.ps1](Discovery_SqlLogin_PrivOnly.ps1) |

### Create Discovery Scanner

1. Navigate to **Admin | Discovery | Extensible Discovery | Configure Discovery Scanners**
1. Navigate to the **Accounts** tab
1. Select **Create New Scanner** (_see table below_)
1. Select **OK**

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
1. Under **Secret Credential** add necessary secret (_if Discovery or Distributed Engine account will not be utilized_)
1. Under **Advanced Settings** adjust the **Scanner Timeout (minutes)** value if necessary
1. Select **OK**

## Next Steps

Once the above configuration has been done, you can trigger Discovery to scan your environment to find all the SQL Logins.
