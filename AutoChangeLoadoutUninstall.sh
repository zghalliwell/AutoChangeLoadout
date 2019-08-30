#!/bin/bash

############
#
# AUTO CHANGE LOADOUT UNINSTALLER
#
# This script can be run to completely uninstall everything from the 
# AutoChangeLoadout workflow. It will check for the launch daemons and if they exist,
# unload and delete them and delete the script as well.
# The logs will remain in /private/var/AutoChangeLoadoutLogs/ in case you need them.
#
# THIS SCRIPT MUST BE RUN WITH SUDO PERMISSIONS
#
############

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

#Check if script exists, if it does, delete it and the previous logs
if [[ -d /private/var/AutoChangeLoadout ]]; then
	rm -rf /private/var/AutoChangeLoadout
	fi
	