# AutoChangeLoadout
Sets up a process to have devices enrolled in Jamf Pro automatically change their loadout at certain times of the day.

About this Script
--------
This script will create a process on a mac that utilizies two launch daemons and the Jamf Pro API to automatically change the loadout of mobile devices at certain times of the day.

For example; a school issues iPads to their students and the students are allowed to take them home with them. During school hours, 8am-4:30pm, the school wants to enforce certain restrictions to lock down the mobile devices and make sure they can only be used for school work. Then at 4:30pm they want those restrictions to be lifted or loosened so that when the student takes the device home, they can play games, listen to music, etc. 

Currently, scheduling functionality does not exist within Jamf Pro so normally you would need to create your own launch daemons to accomplish these tasks. This script will take care of that process for you.

The "AutoChangeLoadoutSetup.sh" script should be run on a single macOS computer that is set to not go to sleep and will always have internet access. It will create three things; a script that will use the Jamf Pro API to move the contents of one Static Device Group to another Static Device Group and two launch daemons that will run the script at specific times of your choosing. The first launch daemon will switch the contents from the second static group into the first static group at a specific time (For instance moving devices from "Home Mode" to "School Mode" at 8am in the morning). And the second launch daemon will move the devices from the first static group to the second static group at a specific time (for instance move them from "School Mode" to "Home Mode" at 4:30pm). It will keep logs of everything it does in /private/var/AutoChangeLoadoutLogs/ and it will flush those logs every three months automatically.

Before you run this script
--------
Before you run this script, you will need to fill in some variables in the information section between lines 1-85.

1. Static Device Group IDs
</br>-First you'll need to configure two STATIC device groups within Jamf Pro for the script to toggle between and make sure all of the necessary devices are scoped to at least one of those static groups. 
</br>-Next, find the ID number of the static group that you would like to use as "Option 1" a.k.a. the group that will define settings for devices during the day. In the example above, this would be similar to "School Mode". Place that ID number between the quotes on line 32. (The id number can be found by going into the settings for the static group and looking at the URL of the webpage. Near the end of the URL it should say "id=" followed by the ID number of that particular object.)
</br>-Next, find the ID number of the static group that you would like to use as "Option 2" a.k.a. the group that will define settings for devices during the evening/night. In the example above, this would be similar to "Home Mode". Place that ID number between the quotes on line 33. (The id number can be found by going into the settings for the static group and looking at the URL of the webpage. Near the end of the URL it should say "id=" followed by the ID number of that particular object.)
</br>-Do you have a lot of devices that need to get added to your static group and don't feel like checking all the boxes. Check out the MUT tool, it makes it really easy to specify a list of Serial Numbers and move them all quickly into a Static group: (https://jssmut.weebly.com/)

2. The next section, between lines 36-46 will have you set the time of day that the devices should toggle between groups. These need to be specified first in the hour of the day (in 24-hour format) and then by the minute of that hour.
</br>-First decide what hour of the day the devices should move into the Static Group from Option 1. (In the example above, when the devices should enter "School Mode") the default is set at "08" for the 8:00am hour of the day. Place that value in the quotes of the variable on line 43.
</br>-Next decide what minute of that hour the devices should move into the Stati Group from Option 1. The default is set to "00" so that it will happen at exactly 8:00 AM. Place that value in the quotes of the variable on line 44.
</br>-Next decide what hour of the day the devices should move into the Static Group from Option 2. (In the example above, when the devices should enter "Home Mode") The default for this is set to "16" so that it happens within the 4:00pm hour of the day. Place that value in the quotes of the variable on line 45.
</br>-Finally, decide what minute of that hour the devices should move into the Static Group from Option 2. The default is set to "30" so that the transition to Option 2 should happen at 4:30 PM. Place that value in the quotes of the variable on line 46.

3. Next, enter your Jamf Pro URL in between the quotes of the variable on line 53. Make sure to include "https://" for example "https://my.jamf.pro".

4. The final piece of the puzzle is authentication. This process will need an API service acount so that it can make changes to your Jamf Pro instance. Within Jamf Pro, go to Settings/Jamf Pro User Accounts and Groups and create a Standard Account with Custom Privileges. Only give the account privileges to READ and UPDATE Static Mobile Device Groups.
</br>-Encryption; once that account is created, you'll need to encrypt the username and password. Don't worry this is easier than it sounds. You can use my Mr Encryptor tool (located here: https://github.com/zghalliwell/MrEncryptor) to encrypt the username and password and generate a SALT and PASSPHRASE for both of them. The tool's instructions will walk you through what to do. Essentially run that Mr Encryptor script, it will prompt you to enter a string that you want to encrypt so enter the username of the API account. It will then copy the ENCRYPTED STRING, SALT, and PASSPHRASE to your clipboard. Paste the contents somehwere so you can read them, and copy the three pieces into the quotes for the variables on lines 74-76. Repeat the process to encrypt the password and past the ENCRYPTED STRING, SALT, and PASSPHRASE into the quotes for the password variables on lines 82-84.
</br>-Now I know what you're thinking, how is it secure if we're putting all three pieces of the encryption key into the same script. This script is only setting everything up and should only be run once, at which point you can delete it. What it will do is pass the ENCRYPTED STRINGS of the username and password down into the script itself so the script will be written with the strings hard coded into it. The script will be written in the /private/var folder inside a folder that only the root user can read/write/execute. No one else will be able to view it without superuser permissions. Then the SALT and PASSPHRASES for both strings will be written to the launch daemons as parameters to pass into the script when the launch daemons run the script so the pieces of the key will only come together when the launch daemon runs the script and only by the root user. </br>Once you've got those four steps done, you can run the script WITH SUDO and it will write the two launch daemons, give them the correct permissions, write the script with the correct permissions and then load the launch daemons and they will trigger at the time you specified. </br>If you ever need to check the logs to troubleshoot, they will be located in /private/var/AutoChangeLoadoutLogs/AutoChangeLoadoutLogs.txt. These logs will automatically flush themselves after 3 months and start fresh.

How to Run
--------
If you're unfamiliar with how to run a script on macOS, simply download the script to your desktop. Open the Terminal application, type in "sudo" and then either type in the path to the script or simply drag the script from whereever you downloaded it and drop it onto the terminal window. Hit enter and it will ask you for a password, since you're running it as a super user, and enter the password of the account you're signed into. You need to be signed in as an administrator for this to work.

Uninstallation
--------

If you need to uninstall this software and start over, simply run the AutoChangeLoadoutUninstall.sh script located in this respository. It will look for the launch daemons and unload them and delete them if they exist and it will look for the script and delete it as well, but it will leave the logs behind in case you need them. This script must be run with SUDO privileges as well.

