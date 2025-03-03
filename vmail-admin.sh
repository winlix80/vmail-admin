#!/bin/bash

###################################################
################  DEFINITIONS  ####################
database_name=vmail # Name of the databse which will be created or used if it still exists 
database_user=vmail	# Username for the "vmail" database ( should not be "root" for security reason or dont save pwd for "root" here )
database_pwd=vmail	# Password for the User
new_user_quota=2048 # Quote in MB
new_user_enabled=1
new_user_sendonly=0
max_quota=4096 #in MB
init_database_user=root #User for create database ( most of time will be root )
init_database_pwd=		#leave empty if you want to put the password in the prompt
###################################################
#################  COMMANDS  ######################
mysqlcmd="mysql -u $database_user -p${database_pwd} -D $database_name"
mysqlcmdinit="mysql -u $init_database_user -p${init_database_pwd}"
###################################################
##################  MENUS  ########################
menu()
{
	printline
	echo "Welcome!"
		echo "1) User Management"
		echo "2) Domain Management"
		echo "3) Aliases Management"
		echo "4) Database Management"
		echo "0) Exit"
	printline
	read choose

	case "$choose" in
		1)
		  user_menu
		  ;;

		2)
		  domain_menu
		  ;;

		3)
		  aliases_menu
		  ;;

		4)
		  database_menu
		  ;;

		0)
		  exit
		  ;;

		*)
		  menu
	esac
	exit
}

user_menu()
{
	printline
	echo "1) Add user"
	echo "2) Delete user"
	echo "3) Show all user"
	echo "4) Change user password"
	echo "5) Change user quota"
	echo "0) Back to main menu"
	printline
	read choose

	case "$choose" in
		1)
		  add_user
		  ;;

		2)
		  delete_user
		  ;;

		3)
		  show_all_user 
		  ;;

		4)
		  change_pass
		  ;;

		5)
		  change_quota
		  ;;

		0)
		  menu
		  ;;

		*)
		  user_menu
	esac
	user_menu
}

domain_menu()
{
	printline
	echo "1) Add Domain"
	echo "2) Delete Domain"
	echo "3) Show users for domain"
	echo "4) Show all domains"
	echo "0) Back to main menu"
	printline
	read choose

	case "$choose" in
		1)
		  add_domain
		  ;;

		2)
		  delete_domain
		  ;;

		3)
		  show_domain_users
		  ;;

		4)
		  show_domains
		  ;;

		0)
		  menu
		  ;;

		*)
		  domain_menu
	esac
	domain_menu
}

aliases_menu()
{
	printline
	echo "1) Add alias"
	echo "2) Delete alias"
	echo "3) Show aliases for domain"
	echo "4) Show all aliases"
	echo "0) Back to main menu"
	printline
	read choose

	case "$choose" in
		1)
		  add_alias
		  ;;

		2)
		  delete_alias
		  ;;

		3)
		  show_alias_domain
		  ;;

		4)
		  show_all_aliases
		  ;;

		0)
		  menu
		  ;;

		*)
		  aliases_menu
	esac
	aliases_menu
}

database_menu()
{
	printline
	echo "1) Export database as sql.gz"
	echo "2) Import database from sql.gz"
	echo "3) Delete database"
	echo "4) Initialize database"
	echo "0) Back to main menu"
	printline
	read choose

	case "$choose" in
		1)
		  export_database
		  ;;

		2)
		  import_database
		  ;;

		3)
		  delete_database
		  ;;

		4)
  		  init_database
			;;

		0)
		  menu
		  ;;

		*)
		  database_menu
	esac
	database_menu
}

###################################################
#############  Shared functions  ##################
printline()
{
	echo ""
}

check_database_exists()
{
	if [ "$database_exists" != "TRUE" ]; then
		echo "It seems the database doesn't exist!"
		echo "Plase initialize the database!"
		database_menu
	fi
}

read_username()
{
	echo "Enter username:"
	read username
	printline
}

read_domain()
{
	echo "Enter domain:"
	read domain
	printline
}

read_note()
{
	echo "Enter note:"
	read note
	printline
}

switch_case_submenu()
{
	case "$1" in
		"user_menu")
		  user_menu
		  ;;

		"domain_menu")
		  domain_menu
		  ;;

		"aliases_menu")
		  aliases_menu
		  ;;

		"database_menu")
		  database_menu
		  ;;

		*)
		  menu
	esac
	menu
}

check_user_exists()
{
	user_exists=`$mysqlcmd -e "select * from accounts where username='$1' and domain='$2';"`
	if [ "$user_exists" == "" ]; then
		echo "User $1@$2 doesn't exist in database!"
		switch_case_submenu $3
	fi
}

check_user_not_existing()
{
	user_exists=`$mysqlcmd -e "select * from accounts where username='$1' and domain='$2';"`
	if [ "$user_exists" != "" ]; then
		echo "User $1@$2 doesn't exist in database!"
		switch_case_submenu $3
	fi
}

check_domain_exists()
{
	domain_exists=`$mysqlcmd -e "select * from domains where domain='$1';"`
	if [ "$domain_exists" == "" ]; then
		echo "Domain $1 doesn't exist in database!"
		switch_case_submenu $2
	fi
}

read_alias_input()
{
	echo "Type alias username:"
	read source_username
	echo "Type alias domain:"
	read source_domain
	check_domain_exists $source_domain "aliases_menu"
	echo "Using $source_username@$source_domain as alias."
	echo "Type destination username:"
	read destination_username
	echo "Type destination domain:"
	read destination_domain
	echo "Using $destination_username@$destination_domain as destination address."
	read_note
}

####################################################################
###################  Database functions  ###########################
export_database()
{
	check_database_exists
	mysqldump -u $init_database_user -p${init_database_pwd}  $database_name | gzip > $database_name-export.sql.gz
	echo "Database has been exported as $database_name-export.sql.gz"
	database_menu
}

import_database()
{

	database_exists=`$mysqlcmd -e "show databases like '$database_name';"`
	if [ "$database_exists" == "" ]; then
		echo "Seems the database $database_name doesn't exist. Creating..."
		$mysqlcmdinit -e "create database $database_name CHARACTER SET 'utf8';";
	else
		echo "Are you sure you want to import into database $database_name?"
		echo "All contents of the database will be overwritten. Enter \"YES\""
		read ack
		if [ "ack" != "YES" ]; then
			echo "Returning to menu."
			printline
			database_menu
		fi
	fi

	echo "Type path to file that you want to import:"
	read import_database_filename
	gunzip < $import_database_filename  | $mysqlcmdinit -D $database_name
	echo "Database $database_name has been created and imported!"
	database_menu
}

delete_database()
{
	database_exists=`$mysqlcmd -e "show databases like '$database_name';"`
	if [ "$database_exists" != "" ]; then
		echo "Are you sure you want to delete database $database_name? Type \"YES\""
		read ack
		if [ "$ack" != "YES" ]; then
			echo "Aborting!"
			database_menu
		fi
		$mysqlcmdinit -e "drop database $database_name";
		echo "Deleted database $database_name!"
	fi
	database_menu
}

init_database()
{
	database_exists=`$mysqlcmdinit -e "show databases like '$database_name';"`
	if [ "$database_exists" != "" ]; then
		echo "The database allready exists!"
		echo "Returning to menu."
		printline
		database_menu
    else
		$mysqlcmdinit -e "create database $database_name CHARACTER SET 'utf8';";
		echo "Database $database_name created!"

		for (( ; ; ))
		do
			echo "Please type password for new database user $database_user:"
			read -s init_database_password
			echo "Please retype password:"
			read -s init_database_password_check
			if [ "$init_database_password" == "$init_database_password_check" ]; then
				$mysqlcmdinit -e "grant select, insert, delete, update on $database_name.* to '$database_user'@'localhost' identified by '$init_database_password';"
				echo "Acces for user $database_user granted!"
				break
			else
				echo "Passwords don't match!"
			fi
		done
		$mysqlcmdinit -D $database_name -e "CREATE TABLE domains ( id int unsigned NOT NULL AUTO_INCREMENT, domain varchar(255) NOT NULL, PRIMARY KEY (id),UNIQUE KEY (domain));"

		$mysqlcmdinit -D $database_name -e "CREATE TABLE accounts ( id int unsigned NOT NULL AUTO_INCREMENT, username varchar(64) NOT NULL,
		domain varchar(255) NOT NULL, password varchar(255) NOT NULL, quota int unsigned DEFAULT '0', enabled boolean DEFAULT '0', sendonly boolean DEFAULT '0', note text DEFAULT NULL,
		PRIMARY KEY (id), UNIQUE KEY (username, domain), FOREIGN KEY (domain) REFERENCES domains (domain));"

		$mysqlcmdinit -D $database_name -e "CREATE TABLE aliases ( id int unsigned NOT NULL AUTO_INCREMENT, source_username varchar(64) NOT NULL, 
		source_domain varchar(255) NOT NULL, destination_username varchar(64) NOT NULL, destination_domain varchar(255) NOT NULL, enabled boolean DEFAULT '0', note text DEFAULT NULL, 
		PRIMARY KEY (id), UNIQUE KEY (source_username, source_domain, destination_username, destination_domain), FOREIGN KEY (source_domain) REFERENCES domains (domain));"

		$mysqlcmdinit -D $database_name -e "CREATE TABLE tlspolicies ( id int unsigned NOT NULL AUTO_INCREMENT, domain varchar(255) NOT NULL,
		policy enum('none', 'may', 'encrypt', 'dane', 'dane-only', 'fingerprint', 'verify', 'secure') NOT NULL, params varchar(255), PRIMARY KEY (id), UNIQUE KEY (domain));"

		echo "Database $database_name created and initialized."
		database_exists=TRUE
		database_menu
	fi
	database_menu
}

###################################################
#############  Alias functions  ###################
add_alias()
{
	check_database_exists
	read_alias_input
	$mysqlcmd -e "insert into aliases (source_username, source_domain, destination_username, destination_domain, enabled, note) values ('$source_username', '$source_domain', '$destination_username', '$destination_domain', true, '$note');"
	echo "Alias $source_username@$source_domain -> $destination_username@$destination_domain has been added"
	aliases_menu
}

delete_alias()
{
	check_database_exists
	read_alias_input
	echo "Do you really want to delete the alias $source_username@$source_domain -> $destination_username@$destination_domain ?"
	echo "Enter \"YES\"!"
	read ack

	if [ "$ack" == "YES" ]; then
		$mysqlcmd -e "delete from aliases where source_username='$source_username' and source_domain='$source_domain' and destination_username='$destination_username'
		and destination_domain='$destination_domain';"
		echo "Alias deleted."
		aliases_menu
	fi
	aliases_menu
}

show_alias_domain()
{
	check_database_exists
	read_domain
	check_domain_exists $domain "aliases_menu"
	show_alias=`$mysqlcmd -e "select * from aliases where source_domain='$domain' or destination_domain='$domain';"`
	if [ "$show_alias" == "" ]; then
		echo "Now aliases for that domain in database!"
		aliases_menu
	fi

	$mysqlcmd -e "select * from aliases where source_domain='$domain' or destination_domain='$domain';"
	aliases_menu
}

show_all_aliases()
{
	check_database_exists
	check_aliases=`$mysqlcmd -e "select * from aliases;"`
	if [ "$check_aliases" == "" ];then
		echo "No aliases in database!"
		aliases_menu
	fi
	$mysqlcmd -e "select * from aliases;"
	aliases_menu
}

###################################################
#############  User functions  ####################
show_all_user()
{
	check_database_exists
	user_exist=`$mysqlcmd -e "select * from accounts;"`
	if [ "$user_exist" == "" ]; then
		echo "No Users in database!"
		user_menu
	else
		$mysqlcmd -e "select id, username, domain, quota, enabled, sendonly, note from accounts;"
		user_menu
	fi
}

add_user()
{
	check_database_exists
	read_username
	read_domain
	read_note
	check_domain_exists $domain "user_menu"
	check_user_not_existing $username $domain "user_menu"

	echo "Domain and user ok!"

	hash=`doveadm pw -s SHA512-CRYPT`

	$mysqlcmd -e "insert into accounts (username, domain, password, quota, enabled, sendonly, note) values ('$username', '$domain', '$hash', '$new_user_quota', '$new_user_enabled', '$new_user_sendonly', '$note');"

	printline
	echo "User $username@$domain has been added!"
	printline
	user_menu
}

change_pass()
{
	check_database_exists
	read_username
	read_domain
	check_domain_exists $domain "user_menu"
	check_user_exists $username $domain "user_menu"

	echo "Is user: $username@$domain correct? Enter \"YES\"!"
	read ack

	if [ "$ack" == "YES" ]; then
		echo "Changing password"
		echo "Type in your new password"
		hash=`doveadm pw -s SHA512-CRYPT`
		$mysqlcmd -e "update accounts set password='$hash' where username='$username';"
		echo "Password of user $username@$domain changed!"
		user_menu
	else
		user_menu
	fi
}

delete_user()
{
	check_database_exists
	read_username
	read_domain
	check_domain_exists $domain "user_menu"
	check_user_exists $username $domain "user_menu"

	echo "Domain and user ok!"
	echo "Are you sure you want to delete $username@$domain? Type \"YES\""
	read ack

	if [ "$ack" != "YES" ]; then
		echo "Aborting!"
		user_menu
	fi

	$mysqlcmd -e "delete from accounts where username='$username' and domain='$domain';"

	printline
	echo "User $username@$domain deleted!"
	user_menu
}

change_quota()
{
	check_database_exists
	read_username
	read_domain
	check_domain_exists $domain "user_menu"
	check_user_exists $username $domain "user_menu"

	echo "Enter new quota in MB:"
	read quota

	if [ $quota -gt $max_quota ]; then
		echo "Quota is bigger then max. quota!"
		user_menu
	fi

	printline
	echo "Changing quota for $username@$domain to $quota MB!"
	$mysqlcmd -e "update accounts set quota='$quota' where username='$username' and domain='$domain';"
	user_menu
}

###################################################
#############  Domain functions  ##################
show_domains()
{
	check_database_exists
	domains_exist=`$mysqlcmd -e "select * from domains;"`
	if [ "$domains_exist" == "" ]; then
		echo "No domains in database!"
		domain_menu
	else
		$mysqlcmd -e "select * from domains;"
		domain_menu
	fi
}

show_domain_users()
{
	read_domain
	check_domain_exists $domain "domain_menu"
	$mysqlcmd -e "select * from accounts where domain='$domain';"
	domain_menu
}

delete_domain()
{
	check_database_exists
	read_domain
	check_domain_exists $domain "domain_menu"

	domain_user_exists=`$mysqlcmd -e "select * from accounts where domain='$domain';"`
	if [ "$domain_user_exists" != "" ]; then
		echo "There are still users for that domain!"
		echo "Please delete those users first!"
		domain_menu
	fi

	alias_exists=`$mysqlcmd -e "select * from aliases where source_domain='$domain' or destination_domain='$domain';"`
	if [ "$alias_exists" != "" ]; then
		echo "There are still aliases for that domain!"
		echo "Please delete those aliases first!"
		domain_menu
	fi

	echo "Are you sure you want to delete $domain? Type \"YES\""
	read ack

	if [ "$ack" != "YES" ]; then
		echo "Aborting!"
		domain_menu
	fi

	$mysqlcmd -e "delete from domains where domain='$domain';"

	printline
	echo "Domain $domain has been deleted!"
	domain_menu
}

add_domain()
{
	check_database_exists
	read_domain

	domain_exists=`$mysqlcmd -e "select * from domains where domain='$domain';"`
	if [ "$domain_exists" != "" ]; then
		echo "Domain $domain exists!"
		domain_menu
	fi
	$mysqlcmd -e "insert into domains (domain) values ('$domain');"
	printline
	echo "Domain $domain has been added"
	domain_menu
}

################################################
##################  MAIN  ######################

if [ $database_user == "root" ]; then
	if [[ $EUID -ne 0 ]]; then
		echo "This script must be run as root"
		exit 1
	fi
fi

database_exists=`$mysqlcmd -e "show databases like '$database_name';"`
if [ "$database_exists" == "" ]; then
	echo "It seems the database $database_name doesn't exist."
	echo "You can initialize the database in the Database Management Menu"
	printline
else
	database_exists=TRUE
	echo "Database $database_name exists."
fi

#echo "Please enter database password for user $database_user:"
#read -s database_password
#Set password to nopass if user is allowed to log in without password
#This way mysql doesn't ask for a password all the time
#if [ "$database_password" == "" ]; then
#	database_password="nopass"
#fi

menu

exit
