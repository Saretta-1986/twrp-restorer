#!/usr/bin/env bash
echo "input the path of TWRP backup"
read backuppath
cd $backuppath
# List of files to be extracted
for f in data.*.win*
do
    tar -xvf "$f" 
done
exit 0
