#!/bin/bash

# Use wget to fetch a complete webpage

url=$1
domain=$(awk -F/ '{print $3}' <<<"$url")

if [ $# -eq 0 ]; then
    echo "Usage: $0 <URL>"
    exit 1
fi

wget --no-cookies --timestamping --recursive --no-clobber --page-requisites --convert-links --adjust-extension -t 10 --random-wait --restrict-file-names=windows -e robots=off -U 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.6) Gecko/20070802 SeaMonkey/1.1.4' --no-check-certificate --domains "$domain" --level=1 --max-redirect=0 --no-parent "$url"
