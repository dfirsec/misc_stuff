#!/bin/bash

# Use wget to fetch a complete webpage or specific files from a website.
# https://www.gnu.org/software/wget/manual/wget.html

# Help menu
function show_help {
    echo "Usage: $0 [-w|-e <file_extension>|-d <directory>] <URL>"
    echo
    echo "Options:"
    echo "  -w <URL>            Download the complete webpage."
    echo "  -e <file_extension> Download files of a specific extension."
    echo "  -s <directory>      Specify the directory to save downloaded files."
    echo "  -l <file>           Log messages to the specified file."
    echo "  -d                  Enable debug mode."
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

# Function to download files in parallel
download_in_parallel() {
    local url=$1
    local extension=$2
    local dir=$3
    local log_file=$4

    # Temporary file to hold the URLs
    local urls_file
    urls_file=$(mktemp)

    # List all URLs matching the extension and save temporary file
    wget --spider --recursive --level=inf --no-parent --accept "$extension" --output-file="$log_file" -o /dev/null "$url" | grep '^--' | awk '{ print $3 }' >"$urls_file"

    # Download files in parallel using xargs
    xargs <"$urls_file" -n 1 -P 10 -I {} wget -P "$dir" {}

    # Clean up the temporary file
    rm "$urls_file"
}

# Initialize variables
domain=""
user_agent="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.6) Gecko/20070802 SeaMonkey/1.1.4"
dir="."
url_set=false
log_file=""

while getopts ":w:e:s:dl:h" opt; do
    case $opt in
    w)
        url=$OPTARG
        url_set=true
        ;;
    e)
        if [[ $OPTARG == -* ]]; then
            echo "Error: Option -e requires an argument."
            exit 1
        fi
        extension=$OPTARG
        ;;
    s)
        if [[ $OPTARG == -* ]]; then
            echo "Error: Option -s requires an argument."
            exit 1
        fi
        dir=$OPTARG
        ;;
    d)
        debug=true
        ;;
    l)
        log_file=$OPTARG
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

# Check if the URL is set
if ! $url_set; then
    echo "Error: A URL must be provided with -w option."
    exit 1
elif [[ ! $url =~ ^https?:// ]]; then
    echo "Invalid URL: $url"
    exit 1
fi

domain=$(awk -F/ '{print $3}' <<<"$url")

wget_options=(
    --limit-rate=20K              # Limit the download speed
    --no-cookies                  # Ignore cookies
    --timestamping                # Do not retrieve files unless newer than local
    --recursive                   # Enable recursive retrieving
    --page-requisites             # Get all images, etc. needed to display HTML page
    --convert-links               # Convert links so that they work locally
    --adjust-extension            # Save files with .html on the end
    --tries=10                    # Set number of retries to 10
    --random-wait                 # Randomly wait 0.5 to 1.5 seconds between retrievals
    --restrict-file-names=windows # Modify filenames to be compatible with Windows
    -e robots=off                 # Ignore robots.txt
    --no-check-certificate        # Ignore SSL certificate errors
    --span-hosts                  # Enable spanning across hosts when doing recursive retrieving
    --domains "$domain"           # Do not follow links outside this domain
    --level=2                     # Specify recursion maximum depth level
    --max-redirect=1              # Maximum number of redirections to follow for a resource
    --no-parent                   # Do not ascend to the parent directory when retrieving recursively
    -U "$user_agent"              # Identify as agent-string to the HTTP server
    -P "$dir"                     # Save files to the specified directory
)

if [[ -n "$log_file" ]]; then
    wget_options+=("--output-file=$log_file")
fi

if [[ -n "$extension" ]]; then
    # wget_options+=("-A *.$extension")
    download_in_parallel "$url" "$extension" "$dir" "$log_file"
fi

if [[ -n "$debug" ]]; then
    wget_options+=("--debug")
fi

# Download the complete webpage or specific files
wget "${wget_options[@]}" "$url" || {
    echo "Invalid URL. Usage: $0 [-w|-e <file_extension>|-d <directory>] <URL>"
    exit 1
}
