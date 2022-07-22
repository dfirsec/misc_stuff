#!/bin/bash

USER=$1
REPO=$2

usage() {
    echo -e "\nUsage:\n${0} username repo \n"
}

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

# Check if zip is installed
command -v zip >/dev/null 2>&1 || {
    echo >&2 "Script requires zip and unzip but they're not installed -- use 'sudo apt install zip unzip'."
    exit 1
}

# Create repo backup
SRC=$PWD
DATE=$(date +%d-%m-%Y)
FILE_NAME=$(basename "$PWD")

echo "Backing up $SRC..."
date

zip -r "$FILE_NAME"-"$DATE".zip "$SRC"
echo
echo "Backup finished!"
date

# Check out to a temporary branch:
git checkout --orphan TEMP_BRANCH

# Add all the files:
git add -A

# Commit the changes:
git commit -am "Initial commit"

# Delete the old branch:
git branch -D master

# Rename the temporary branch to master:
git branch -m master

# Switch to SSH:
git remote set-url origin git@github.com:"${USER}"/"$REPO".git

# Finally, force update to our repository:
git push -f origin master
