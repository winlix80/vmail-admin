# vmail-admin

`vmail-admin` is a command line tool for managing a mail-server database
based on the great [HowTo](https://thomas-leister.de/en/mailserver-debian-stretch) ([german version](https://thomas-leister.de/mailserver-debian-stretch/))
from [Thomas Leister](https://thomas-leister.de) written in Bash. 
The databses is extended for field notes in accounts and aliases.

# Installation

* Download vmail-admin.sh.
* Make it executable with "chmod +x vmail-admin.sh".
* Run it with "./vmail-admin.sh".

# Usage

You can change the parameters for the script under Definitions in the script.
Start the script with:
```shell
./vmail-admin.sh
```
Note that you also can initialize the database with this tool.

## Menu

Menu items are:
1. User Management
    1. Add user
    2. Delete user
    3. Show all user
    4. Change user password
    5. Change user quota
    6. Change user sendonly
    7. Enable/Disable user
    8. Back to main menu
2. Domain Management
    1. Add Domain
    2. Delete Domain
    3. Show users for domain
    4. Show all domains
    5. Back to main menu
3. Aliases Management
    1. Add alias
    2. Delete alias
    3. Show aliases for domain
    4. Show all aliases
    5. Back to main menu
4. Database Management
    1. Export database as sql.gz
    2. Import database from sql.gz
    3. Delete database
    4. Initialize database
    5. Back to main menu
5. Exit
