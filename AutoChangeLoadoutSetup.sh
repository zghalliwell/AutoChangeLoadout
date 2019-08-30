#!/bin/bash

####################################
# AUTO-CHANGE-LOADOUT-SETUP
####################################
#
# NOTE: THIS SCRIPT MUST BE RUN WITH SUDO PRIVILEGES
#
# This script will allow you to set up an automated process for moving devices between
# two loadouts at two time intervals per day. For example; a school wants to enforce
# certain restritive configuration profiles on devices during the school day between
# 8am and 4pm and then after 4pm the devices will lose some of the restrictions allowing 
# students to play games or other things in their free time.
#
# The script will create three things on your computer;
# 1. A launch daemon that will execute at a time you choose to put devices into the more restrictive "mode" a.k.a. "OptionOne"
# 2. A launch daemon that will execute at a time you choose to put devices into the less restrictive "mode" a.k.a. "OptionTwo"
# 3. A script for both of the launch daemons to execute that makes the actual changes
#
####################################
# WHAT YOU'LL NEED
####################################
# 
# In Jamf Pro, you'll first need to create two STATIC Mobile Device Groups. One of them should be for the more restrictive mode
# (for instance "School Mode") this will be referred to as "OptionOne" within this script. Then create another STATIC device group
# for the less restrictive mode (for instance "Home Mode") this will be referred to as "OptionTwo" in this script.
# Once created, first add any necessary devices to either one of the static groups and then, take down the IDs of 
# both of those groups and type them into the variables below:
# (Place the ID number between the quotes)
#
####################################
staticGroupOneID="insertStaticGroupOneIDHere"
staticGroupTwoID="insertStaticGroupTwoIDHere"
####################################
#
# Next, you'll need to figure out the time of day that you want devices to switch into "OptionOne" and when to switch back
# to "OptionTwo". Due to how the Launch Daemons will understand time we need to separate the hours and minutes into separate variables.
# In the variables below set the Hour and Minute for OptionOne and OptionTwo. Make sure to state the Hour in military time
# For example "8am" would be Hour: 08 and Minute: 00 and then "4:30pm" would be Hour: 16 and Minute 30
# The defaults set will keep devices in OptionOne between 8am and 4:30pm, but you can change them to whichever times you would like
#
####################################
optionOneHour=08
optionOneMinute=00
optionTwoHour=16
optionTwoMinute=30
####################################
#
# The next thing we'll need is just your Jamf Pro URL. Enter it in the variable below, 
# make sure to enter the "https://" at the beginning of it too!
#
####################################
jamfProURL="https://my.jamf.pro"
####################################
#
# The final piece of the puzzle; AUTHENTICATION!
# This script utilizes 256 bit encryption to protect the username and password 
# of the API account that will be used to move devices between the two Static Groups.
# Any full access admin account will work, but it is recommended, for security reasons
# to create a dedicated service API account in Jamf Pro with only permissions to 
# READ and UPDATE Static Mobile Device Groups.
#
# Once you have an account, you'll need to encrypt the username and password
# You can use my Mr Encryptor tool, linked below, to encrypt your username and password
# and generate an encrypted string for each of them as well as a SALT and PASSPHRASE that will
# be used to decrypt them.
#
# https://github.com/zghalliwell/MrEncryptor
#
# Once you have the username encrypted, enter the ENCRYPTED STRING, SALT, and PASSPHRASE in the appropriate
# variables below, making sure to keep them in the quotes:
#
########################################################################
usernameENCRYPTEDSTRING="insertUsernameEncryptedStringHere"
usernameSALT="insertUsernameSaltHere"
usernamePASSPHRASE="insertUsernamePassphraseHere"
########################################################################
#
# Now encrypt the password and do the same thing with the variables below:
#
########################################################################
passwordENCRYPTEDSTRING="insertPasswordEncryptedStringHere"
passwordSALT="insertPasswordSaltHere"
passwordPASSPHRASE="insertPasswordPassphraseHere"
########################################################################
#
# Now that that's done the ENCRYPTED STRINGS will be passed down into the main script itself when it's created
# and the the SALT and PASSPHRASE for both of them will be passed through as parameters by the Launch Daemons.
# This will help keep the username and password secure by keeping two parts of the decryption key in two separate
# places.
#
# If you've reached this point, you are ready to run this script!
# After it runs for the first time, the actual script will store logs every time it runs in 
# /private/var/AutoChangeLoadoutLogs/AutoChangeLoadoutLogs.txt
# Refer to those logs if you ever notice any issues.
#
# Also, if you bork any variables, you can always re-run the script after you change the variables
# Every time you run this script, it will unload and delete the launch daemons if they exist
# and nuke and recreate the AutoChangeLoadout folder.
#
# Once you're finished and have reached the desired result, either delete this script or erase variables you
# entered for the encrypted username and password to make sure they're not sitting out where someone can find them.
#
########################################################################

##################
# BEGINNING CHECKS
##################

#Check if script's folder exists, if it does, delete it and its contents, and then recreate it
#if it doesn't exist, make it
if [[ -d /private/var/AutoChangeLoadout ]]; then
	rm -rf /private/var/AutoChangeLoadout
	mkdir /private/var/AutoChangeLoadout
	chmod 700 /private/var/AutoChangeLoadout
	chown root:wheel /private/var/AutoChangeLoadout
	else
		mkdir /private/var/AutoChangeLoadout
		chmod 700 /private/var/AutoChangeLoadout
		chown root:wheel /private/var/AutoChangeLoadout
	fi
	
#Check if option one launch daemon exists, if it does, unload it and delete it
if [[ -f /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionOne.plist ]]; then
	#unload the daemon
	launchctl unload /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionOne.plist
	#delete the daemon
	rm -f /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionOne.plist
	fi
	
#Check if option two launch daemon exists, if it does, unload it and delete it
if [[ -f /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionTwo.plist ]]; then
	#unload the daemon
	launchctl unload /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionTwo.plist
	#delete the daemon
	rm -f /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionTwo.plist
	fi 

#################################
# WRITE LAUNCH DAEMONS AND SCRIPT
#################################

#Create the launch daemon for option one
cat << EOF > /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionOne.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.halliwell.autochangeloadoutOptionOne</string>
	<key>ProgramArguments</key>
	<array>
		<string>sh</string>
		<string>-c</string>
		<string>/private/var/AutoChangeLoadout/autoChangeLoadout.sh $usernameSALT $usernamePASSPHRASE $passwordSALT $passwordPASSPHRASE $jamfProURL $staticGroupOneID $staticGroupTwoID option1</string>
	</array>
	<key>StartCalendarInterval</key>
	<array>
		<dict>
			<key>Hour</key>
			<integer>$optionOneHour</integer>
			<key>Minute</key>
			<integer>$optionOneMinute</integer>
			<key>Weekday</key>
			<integer>1</integer>
		</dict>
		<dict>
			<key>Hour</key>
			<integer>$optionOneHour</integer>
			<key>Minute</key>
			<integer>$optionOneMinute</integer>
			<key>Weekday</key>
			<integer>2</integer>
		</dict>
		<dict>
			<key>Hour</key>
			<integer>$optionOneHour</integer>
			<key>Minute</key>
			<integer>$optionOneMinute</integer>
			<key>Weekday</key>
			<integer>3</integer>
		</dict>
		<dict>
			<key>Hour</key>
			<integer>$optionOneHour</integer>
			<key>Minute</key>
			<integer>$optionOneMinute</integer>
			<key>Weekday</key>
			<integer>4</integer>
		</dict>
		<dict>
			<key>Hour</key>
			<integer>$optionOneHour</integer>
			<key>Minute</key>
			<integer>$optionOneMinute</integer>
			<key>Weekday</key>
			<integer>5</integer>
		</dict>
	</array>
</dict>
</plist>
EOF

#Set file mode and group ownership
chmod 644 /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionOne.plist
chown root:wheel /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionOne.plist

#create the launch daemon for Option 2
cat << EOF > /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionTwo.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.halliwell.autochangeloadoutOptionTwo</string>
	<key>ProgramArguments</key>
	<array>
		<string>sh</string>
		<string>-c</string>
		<string>/private/var/AutoChangeLoadout/autoChangeLoadout.sh $usernameSALT $usernamePASSPHRASE $passwordSALT $passwordPASSPHRASE $jamfProURL $staticGroupOneID $staticGroupTwoID option2</string>
	</array>
	<key>StartCalendarInterval</key>
	<array>
		<dict>
			<key>Hour</key>
			<integer>$optionTwoHour</integer>
			<key>Minute</key>
			<integer>$optionTwoMinute</integer>
			<key>Weekday</key>
			<integer>1</integer>
		</dict>
		<dict>
			<key>Hour</key>
			<integer>$optionTwoHour</integer>
			<key>Minute</key>
			<integer>$optionTwoMinute</integer>
			<key>Weekday</key>
			<integer>2</integer>
		</dict>
		<dict>
			<key>Hour</key>
			<integer>$optionTwoHour</integer>
			<key>Minute</key>
			<integer>$optionTwoMinute</integer>
			<key>Weekday</key>
			<integer>3</integer>
		</dict>
		<dict>
			<key>Hour</key>
			<integer>$optionTwoHour</integer>
			<key>Minute</key>
			<integer>$optionTwoMinute</integer>
			<key>Weekday</key>
			<integer>4</integer>
		</dict>
		<dict>
			<key>Hour</key>
			<integer>$optionTwoHour</integer>
			<key>Minute</key>
			<integer>$optionTwoMinute</integer>
			<key>Weekday</key>
			<integer>5</integer>
		</dict>
	</array>
</dict>
</plist>
EOF

#Set file mode and group ownership
chmod 644 /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionTwo.plist
chown root:wheel /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionTwo.plist

#Write the script that the launch daemons will reference

cat << EOF > /private/var/AutoChangeLoadout/autoChangeLoadout.sh
#!/bin/bash

################
# AUTHENTICATION
################
#
# This script utilizes 256 bit encryption to protect the username and password 
# of the API account. The setup script that created this script should have placed
# the encrypted strings in the variables below and the SALT and PASSPHRASE for each of them will be brought in
# as parameters from the Launch Daemon that runs the script to help protect them by keeping
# the two pieces of the key separate.
#
###########################################
usernameEncryptedString="$usernameENCRYPTEDSTRING"
passwordEncryptedString="$passwordENCRYPTEDSTRING"
###########################################
#
# You can use my Mr Encryptor script located at the link below to encrypt
# your username and password and generate the encrypted string, salt and passphrase:
#
# https://github.com/zghalliwell/MrEncryptor
#
# The API account will need READ and UPDATE privileges on STATIC mobile device groups	
#
# ESTABLISHING DECRYPTION FUNCTION:
################################################################################
function DecryptString() {
	echo "\${1}" | /usr/bin/openssl enc -aes256 -d -a -A -S "\${2}" -k "\${3}"
}
################################################################################

usernameSALT="\$1"
usernamePASSPHRASE="\$2"
passwordSALT="\$3"
passwordPASSPHRASE="\$4"
adminUser=\$(DecryptString "\$usernameEncryptedString" "\$usernameSALT" "\$usernamePASSPHRASE")
adminPass=\$(DecryptString "\$passwordEncryptedString" "\$passwordSALT" "\$passwordPASSPHRASE")
jamfProURL="\$5"
staticGroupOneID="\$6"
staticGroupOneContents=
staticGroupOneSize=
staticGroupOneDeviceIDs=()
staticGroupOneName=
staticGroupOneXML=
staticGroupTwoID="\$7"
staticGroupTwoContents=
staticGroupTwoSize=
staticGroupTwoDeviceIDs=()
staticGroupTwoName=
staticGroupTwoXML=
toggle="\$8"
logPath=/private/var/AutoChangeLoadoutLogs/AutoChangeLoadoutLogs.txt
currentDateTime=\$(date)

#Check if the Logs folder exists, if it doesn't then create it.
if [[ ! -d /private/var/AutoChangeLoadoutLogs ]]; then
	#Create the directory and the log file and change ownership of the folder so end user can access it
	mkdir /private/var/AutoChangeLoadoutLogs
	touch /private/var/AutoChangeLoadoutLogs/AutoChangeLoadoutLogs.txt
	chmod -R 755 /private/var/AutoChangeLoadoutLogs
	else
		#If the log file already exists, check how old it is
		logBirth=\$(stat -f %B "/private/var/AutoChangeLoadoutLogs/AutoChangeLoadoutLogs.txt")
		
		#Grab the current date and convert it to epoch time
		currentDate=\$(date +%s)
		
		#Calculate the time difference between the date the logs were created, and today's date
		timeDifference=\$(echo \$((\$currentDate-\$birthDate)))

		#If the logs are older than 3 months, flush them and create a new log file
		if [[ \$timeDifference -gt 7776000 ]]; then
			rm -f /private/var/AutoChangeLoadoutLogs/AutoChangeLoadoutLogs.txt
			echo "Previous logs flushed on \$currentDateTime" >> \$logPath
			echo "Starting new log file..." >> \$logPath
				fi
	fi 

echo "##############################
# Running AutoChangeLoadout
# Current Date/Time: \$currentDateTime
##############################" >> \$logPath

################################
# GATHER INFO FROM STATIC GROUPS
################################

echo \$(date) "Gathering preliminary info..." >> \$logPath

#Get the Contents of Static Group One and save as a variable
staticGroupOneContents=\$(curl -su \$adminUser:\$adminPass \$jamfProURL/JSSResource/mobiledevicegroups/id/\$staticGroupOneID -H "Accept: text/xml" -X GET | xmllint --format -)

#Get the size of Static Group One and save that as a variable
staticGroupOneSize=\$(echo \$staticGroupOneContents | xmllint --xpath '/mobile_device_group/mobile_devices/size/text()' -)

#Get the name of Static Group Two and save that as a variable
staticGroupOneName=\$(echo \$staticGroupOneContents | xmllint --xpath '/mobile_device_group/name/text()' -)

#Get the contents of Static Group Two and save as a variable
staticGroupTwoContents=\$(curl -su \$adminUser:\$adminPass \$jamfProURL/JSSResource/mobiledevicegroups/id/\$staticGroupTwoID -H "Accept: text/xml" -X GET | xmllint --format -)

#Get the size of Static Group Two and save that as a variable
staticGroupTwoSize=\$(echo \$staticGroupTwoContents | xmllint --xpath '/mobile_device_group/mobile_devices/size/text()' -)

#Get the name of Static Group Two and save that as a variable
staticGroupTwoName=\$(echo \$staticGroupTwoContents | xmllint --xpath '/mobile_device_group/name/text()' -)

########################################
# ESTABLISH FUNCTIONS FOR MOVING DEVICES 
########################################

function getStaticGroupTwoIDs {
#Get a list of IDs of devices in Group Two and save them to an array
for i in \$(seq 1 \$staticGroupTwoSize); do
	staticGroupTwoDeviceIDs+=( "\$(echo \$staticGroupTwoContents | xmllint --xpath "/mobile_device_group/mobile_devices/mobile_device[\$i]/id/text()" -)" )
	done
	
	#set an index for targetting the array later
	index=\$((\$staticGroupTwoSize-1))
}

function getStaticGroupOneIDs {
#Get a list of IDs of devices in Group One and save them to an array
for i in \$(seq 1 \$staticGroupOneSize); do
	staticGroupOneDeviceIDs+=( "\$(echo \$staticGroupOneContents | xmllint --xpath "/mobile_device_group/mobile_devices/mobile_device[\$i]/id/text()" -)" )
	done
	
	#set an index for targetting the array later
	index=\$((\$staticGroupOneSize-1))
}

function removeDevicesFromGroupTwo {
#Build the XML to remove devices from Group Two
for i in \$(seq 0 \$index); do
	staticGroupTwoXML="\$staticGroupTwoXML<mobile_device_deletions><mobile_device><id>\${staticGroupTwoDeviceIDs[\$i]}</id></mobile_device></mobile_device_deletions>"
	done

#Remove all devices from Group Two 
confirmationTwoID=\$(curl -su \$adminUser:\$adminPass \$jamfProURL/JSSResource/mobiledevicegroups/id/\$staticGroupTwoID -H "Content-type: text/xml" -X PUT -d "<mobile_device_group>\$staticGroupTwoXML</mobile_device_group>" | xmllint --xpath '/mobile_device_group/id/text()' -)

if [[ \$confirmationTwoID == \$staticGroupTwoID ]]; then
echo \$(date) "\$staticGroupTwoSize device(s) have been removed from \$staticGroupTwoName" >> \$logPath
	else
		echo \$(date) "An error occured, cancelling...
		
		ERROR: \$confirmationTwoID" >> \$logPath
		exit 1
		fi
}

function removeDevicesFromGroupOne {
#Build the XML to remove devices from Group One
for i in \$(seq 0 \$index); do
	staticGroupOneXML="\$staticGroupOneXML<mobile_device_deletions><mobile_device><id>\${staticGroupOneDeviceIDs[\$i]}</id></mobile_device></mobile_device_deletions>"
	done

#Remove all devices from Group One 
confirmationOneID=\$(curl -su \$adminUser:\$adminPass \$jamfProURL/JSSResource/mobiledevicegroups/id/\$staticGroupOneID -H "Content-type: text/xml" -X PUT -d "<mobile_device_group>\$staticGroupOneXML</mobile_device_group>" | xmllint --xpath '/mobile_device_group/id/text()' -)

if [[ \$confirmationOneID == \$staticGroupOneID ]]; then

echo \$(date) "\$staticGroupOneSize device(s) have been removed from \$staticGroupOneName" >> \$logPath
	else 
		echo \$(date) "An error occured, cancelling...
		
		ERROR: \$confirmationTwoID" >> \$logPath
		exit 1
		fi
}

function addDevicesToGroupOne {
#Build XML for adding IDs to Group One
for i in \$(seq 0 \$index); do
	staticGroupOneXML="\$staticGroupOneXML<mobile_devices><mobile_device><id>\${staticGroupTwoDeviceIDs[\$i]}</id></mobile_device></mobile_devices>"
	done
	
#Add all devices to Group One 
confirmationOneID=\$(curl -su \$adminUser:\$adminPass \$jamfProURL/JSSResource/mobiledevicegroups/id/\$staticGroupOneID -H "Content-type: text/xml" -X PUT -d "<mobile_device_group>\$staticGroupOneXML</mobile_device_group>" | xmllint --xpath '/mobile_device_group/id/text()' -)

if [[ \$confirmationOneID == \$staticGroupOneID ]]; then
echo \$(date) "\$staticGroupTwoSize device(s) have been successfully moved to \$staticGroupOneName
" >> \$logPath

exit 0
	else
		echo \$(date) "An error occured, cancelling...
		
		ERROR: $confirmationOneID" >> \$logPath
		exit 1
		fi
}

function addDevicesToGroupTwo {
#Build XML for adding IDs to Group Two
for i in \$(seq 0 \$index); do
	staticGroupTwoXML="\$staticGroupTwoXML<mobile_devices><mobile_device><id>\${staticGroupOneDeviceIDs[\$i]}</id></mobile_device></mobile_devices>"
	done
	
#Add all devices to Group Two 
confirmationTwoID=\$(curl -su \$adminUser:\$adminPass \$jamfProURL/JSSResource/mobiledevicegroups/id/\$staticGroupTwoID -H "Content-type: text/xml" -X PUT -d "<mobile_device_group>\$staticGroupTwoXML</mobile_device_group>" | xmllint --xpath '/mobile_device_group/id/text()' -)

if [[ \$confirmationTwoID == \$staticGroupTwoID ]]; then
echo \$(date) "\$staticGroupOneSize device(s) have been successfully moved to \$staticGroupTwoName
" >> \$logPath

exit 0
	else
		echo \$(date) "An error occured, cancelling...
		
		ERROR: \$confirmationTwoID" >> \$logPath
		exit 1
		fi
}

#########################
# TOGGLE GROUP MEMBERSHIP
#########################

#Chech which option is being passed into the script from the launch daemon and run the appropriate functions

case \$toggle in

	"option1")
		echo \$(date) "Moving devices to \$staticGroupOneName..." >> \$logPath
		
		#Run the function to get IDs of devices in group two
		getStaticGroupTwoIDs
		
		#Run the function to remove devices from group two
		removeDevicesFromGroupTwo
		
		#Run the function to add devices to group one
		addDevicesToGroupOne
		;;
	
	"option2")
		echo \$(date) "Moving devices to $staticGroupTwoName..." >> \$logPath
		
		#Run the function to get IDs of devices in group one
		getStaticGroupOneIDs
		
		#Run the function to remove devices from group one
		removeDevicesFromGroupOne
		
		#Run the function to add devices to group two
		addDevicesToGroupTwo
		;;
		
	*)
		#Anything else would mean the toggle variable didn't pass correctly, report to logs and error out
		echo \$(date) "It appears there is a problem with the script, ensure you didn't change the Toggle variable" >> \$logPath
		exit 1
		;;
	
	esac
EOF

#Set file mode and group ownership
chmod 755 /private/var/AutoChangeLoadout/autoChangeLoadout.sh
chown root:wheel /private/var/AutoChangeLoadout/autoChangeLoadout.sh

#Load the launch daemons
launchctl load /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionOne.plist
launchctl load /Library/LaunchDaemons/com.halliwell.autochangeloadoutOptionTwo.plist

osascript -e 'tell application "System Events" to (display dialog "Success! There are now two launch daemons created on this computer and a script has been created in /private/var/AutoChangeLoadout that the launch daemons will reference. A log folder will be available in /private/var once the script runs for the first time and the logs will automatically flush every three months.

If you need to uninstall this software, run the uninstaller script on the github repo. If you just need to turn it off temporarily, simply unload the following two Launch Demons:

com.halliwell.autochangeloadoutOptionOne.plist
com.halliwell.autochangeloadoutOptionTwo.plist

Have an awesome day!" buttons {"OK"} default button 1)'
