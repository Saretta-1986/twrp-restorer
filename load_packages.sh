#!/usr/bin/env bash

echo "###########################################################################################################"
echo "#                                   Restore Apps from TWRP Backup                                         #"
echo "#                                                                                                         #"
echo "# This is a bash script that automates the process of manually restoring android apps from a TWRP backup. #"
echo "###########################################################################################################"
echo "##                           Don't TWRP backups have a restore process?                                  ##"
echo "###########################################################################################################"
echo "#            Well, yes. A TWRP data restore reflashes all your andorid app data /data/data.               #"	
echo "#            However, if you just completely wiped your phone during a ROM upgrade or change              #"
echo "#                You may not want to/ be able to restore all your applications.                           #"
echo "#                This script allows you to automate the manual restore process                            #"
echo "#                 So you can be selective about what applications you restore.                            #"
echo "###########################################################################################################"
echo "##                                      How does it work?                                                 #"
echo "###########################################################################################################"
echo "#                 1. Extract data archives                                                                #"
echo "#                 2. Connects to phone via adb                                                            #"
echo "#                 3. Install app on phone                                                                 #"
echo "#                 4. Pushes TWRP app data backup to android app data location                             #"
echo "#                 5. Gets the userId for the app                                                          #"
echo "#                 6. Changes ownership of app data folders to application via the userId                  #"
echo "#                 7. Restore the SELinux attributes of the folder                                         #"
echo "###########################################################################################################"

path=$(pwd)
echo "input the path of TWRP backup"
read backuppath

# List of files to be extracted
for f in $backuppath/data.*.win*
do
    tar -xvf "$f" -C ${path}
done

# The following resources were used in the creation of this script.
# https://www.semipol.de/2016/07/30/android-restoring-apps-from-twrp-backup.html
# https://itsfoss.com/fix-error-insufficient-permissions-device/

# TWRP extract location for data/data/
# Change if necessary!
localpackages="data/data/"
localapkpath="data/app" # do not append '/'
# Android delivery destination
remotepackages='/data/data/'

# filename of packages in data/data/ to restore
declare -a packages=(
"change.these.names"
"com.first.app"
"com.second.app"
"com.third.app"
"com.more.apps"
)

printf "=========================================================\n"
printf "Killing ADB server\n"
adb kill-server
printf "Starting ADB server with sudo\n"
sudo adb start-server
printf "Starting ADB as root\n"
adb root
printf "=========================================================\n"


for package in ${packages[*]}
do
    printf "=========================================================\n"
    printf "Killing %s\n" $package
    adb shell am force-stop $package
    printf "Clearing %s\n" $package
    adb shell pm clear $package
    
    printf "Reinstalling apk of %s\n" $package
    apkpath=$(find "${localapkpath}" -maxdepth 3 -type d -print | grep $package | head -n1)
    adb install -r "$apkpath/base.apk"
    
    printf "Restoring %s\n" $package
    adb push "$localpackages$package" $remotepackages
    printf "Correcting package\n"
    userid=$(adb shell dumpsys package $package | grep userId | cut -d "=" -f2-)
    adb shell chown -R $userid:$userid $remotepackages$package
    adb shell restorecon -Rv $remotepackages$package
    printf "Package restored on device\n"
    sleep 1
    
done

