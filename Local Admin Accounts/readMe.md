# Local Administrators Account Discovery

The Local Adminsitrators Account Discovery will find local admin accounts on the machines. It will ignore domain accounts, and nested groups.

| Environment | Version |
| ------ | ------ |
| Secret Server | 10.0+ |
| Operating System | 2008 and above |
| PowerShell | Windows Management Framework 3+ |

## Prerequisites

- Port 445 open

## Installation

1. Add the script in Secret Server:
    - **ADMIN** > **Scripts**
2. Configure Discovery Scanner:
    - **ADMIN** > **Discovery** > **Extensible Discovery** > **Configure Discovery Scanners** >
    - **Local Accounts** > **Create New Scanner:**
        - **Scanner Name:** > Choose a name
        - **Base Scanner:** PowerShell Discovery
        - **Input Template:** Windows Computer
        - **Output Template:** Local Windows Account
        - **Script:** Select  script from step 1
        - **Arguments:** $target
3. Adding the Scanner
    - **ADMIN** > **Discovery** > **Edit Discovery Sources** and select your source
    - Click on **Scanner Settings** Tab
    - Scroll down to **Find Local Accounts** > **Add New Local Account Scanner**
    - Select your scanner from the scanner list
4. Run Discovery