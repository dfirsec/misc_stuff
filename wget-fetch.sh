#!/bin/bash

# Use wget to fetch a complete webpage or specific files from a website.

# Help menu
function show_help {
    echo "Usage: $0 [-w|-e <file_extension>|-d <directory>] <URL>"
    echo
    echo "Options:"
    echo "  -w <URL>            Download the complete webpage."
    echo "  -e <file_extension> Download files of a specific extension."
    echo "  -d <directory>      Specify the directory to save downloaded files."
    echo "  -h                  Display this help message."
    echo
    echo "Example:"
    echo "  $0 -w https://example.com"
    echo "  $0 -e pdf -d /path/to/directory https://example.com"
    exit 0
}

# Check if wget is installed
if ! command -v wget &>/dev/null; then
    echo "wget could not be found"
    exit 1
fi

domain=""
user_agent="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.6) Gecko/20070802 SeaMonkey/1.1.4"
dir="."

while getopts ":w:e:d:h" opt; do
    case $opt in
    w)
        url=$OPTARG
        ;;
    e)
        if [[ -z $OPTARG ]]; then
            echo "File extension must be provided with -e option"
            exit 1
        else
            extension=$OPTARG
        fi
        ;;
    d)
        dir=$OPTARG
        ;;
    h)
        show_help
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    esac
done

# Check if URL is provided and is valid
if [[ -z "$url" ]]; then
    echo "A URL must be provided."
    show_help
elif [[ ! $url =~ ^https?:// ]]; then
    echo "Invalid URL: $url"
    exit 1
fi

domain=$(awk -F/ '{print $3}' <<<"$url")

wget_options=(
    --no-cookies
    --timestamping
    --recursive
    --no-clobber
    --page-requisites
    --convert-links
    --adjust-extension
    -t 10
    --random-wait
    --restrict-file-names=windows
    -e robots=off
    --no-check-certificate
    --domains "$domain"
    --level=1
    --max-redirect=0
    --no-parent
    -U "$user_agent"
    -P "$dir"
)

if [[ -n "$extension" ]]; then
    wget_options+=("-A *.$extension")
fi

wget "${wget_options[@]}" "$url" || {
    echo "Invalid URL. Usage: $0 [-w|-e <file_extension>|-d <directory>] <URL>"
    exit 1
}
