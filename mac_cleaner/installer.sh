#!/usr/bin/env bash

function install() {
    echo "Download Mac Cleaner"
    curl -o mac_cleaner https://raw.githubusercontent.com/dfirsec/misc_scripts/master/mac_cleaner/mac_cleaner.sh
    echo "Init Mac Cleaner"
    chmod +x mac_cleaner
    echo "Install Mac Cleaner"
    sudo mv cleaner /usr/local/bin/mac_cleaner
}

function uninstall() {
    echo "Uninstall Mac Cleaner"
    sudo rm /usr/local/bin/mac_cleaner
}

case $1 in
    uninstall)
        uninstall
		exit
        ;;
    update)
        install
        exit
        ;;
    *)
		install
		exit
        ;;
esac
