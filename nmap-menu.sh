#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Purpose:
#   Script to run a selection of common nmap scans
# Arguments:
#   Target IP address
# Output:
#   Nmap scan results to stdout
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Check for input
if [ $# -le 0 ]; then
    echo -e "Usage: $0 [ip address]"
    exit 1
fi

# Color setup
# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
CYAN=$(tput bold && tput setaf 45)
GREEN=$(tput bold && tput setaf 46)
WHITE=$(tput bold && tput setaf 15)
ORANGE=$(tput bold && tput setaf 202)
TERM_GRN=$(tput bold && tput setaf 10)
RED=$(tput bold && tput setaf 196)
RESET=$(tput sgr0)

RUN_SCAN() {
    clear
    INFO "-- $1 --"
    sudo nmap "$2" "${@:3}"
    read -rp "Press any key to return to the main menu..."
}

MAIN_MENU() {
    echo -e "${CYAN}${1}${RESET}"
}

MENU_OPTS() {
    echo -e "${WHITE}${1}${RESET}"
}

INFO() {
    echo -e "${GREEN}${1}${RESET}"
}

ERROR() {
    echo -e "\n${RED}${1}${RESET}"
}

WARN() {
    echo -e "${ORANGE}${1}${RESET}"
}

FIN() {
    echo -e "\n${TERM_GRN}Exited${1}${RESET}"
}

# Validate IP address
IP_REGEX='^(25[0-4]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-4]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-4]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-4]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$'
if ! [[ $1 =~ $IP_REGEX ]]; then
    ERROR "Invalid IP address format."
    exit 1
fi

MENU() {
    while true; do
        clear
        echo -ne "
$(MAIN_MENU " -- OPTIONS --")
$(MENU_OPTS "  1)") Host Discovery - ICMP Echo
$(MENU_OPTS "  2)") Host Discovery - ICMP Netmask
$(MENU_OPTS "  3)") Host Discovery - ICMP Timestamp
$(MENU_OPTS "  4)") Host Discovery - Port Scanning
$(MENU_OPTS "  5)") Port Scanning (Top 1000)
$(MENU_OPTS "  6)") Service Detection
$(MENU_OPTS "  7)") OS Detection
$(MENU_OPTS "  8)") SSL Certs/Ciphers
$(MENU_OPTS "  9)") Port Scanning (1-65535)
$(MENU_OPTS "  F)") Favorite
$(MENU_OPTS "  0)") Exit
Choose an option:  "
        read -r ans
        case $ans in
        1) RUN_SCAN "Host Discovery - ICMP Echo" "$1" -n -sn -PE -vv ;;
        2) RUN_SCAN "Host Discovery - ICMP Netmask" "$1" -n -sn -PM -vv ;;
        3) RUN_SCAN "Host Discovery - ICMP Timestamp" "$1" -n -sn -PP -vv ;;
        4) RUN_SCAN "Host Discovery - Port Scanning" "$1" -PS21,22,23,25,80,113,443 -PA80,113,443 -n -sn -T4 -vv ;;
        5) RUN_SCAN "Port Scanning (Top 1000)" "$1" --top-ports 1000 -n -Pn -sS -T4 --min-parallelism 100 --min-rate 64 -vv ;;
        6) SERVICE_DETECTION "$1" ;;
        7) RUN_SCAN "OS Detection" "$1" -n -Pn -O -T4 --min-parallelism 100 --min-rate 64 -vv ;;
        8) RUN_SCAN "SSL Certs/Ciphers" "$1" -p 443 -n -Pn --script ssl-cert,ssl-enum-ciphers -T4 -vv ;;
        9) RUN_SCAN "Port Scanning (1-65535)" "$1" -p- -n -Pn -sS -T4 --min-parallelism 100 --min-rate 128 -vv ;;
        F) RUN_SCAN "Favorite Scan" "$1" -sC -sV -Pn --min-rate=1000 -T4 -p- -vv ;;
        0)
            FIN ""
            break
            ;;
        *)
            ERROR "[!] Invalid option"
            read -rp "Press any key to return to the main menu..."
            ;;
        esac
    done
}

# Service detection
SERVICE_DETECTION() {
    read -rp "  Enter port(s) [e.g., 80 or 80,443 or 80-100]: " PORT
    if ! [[ $PORT =~ ^([0-9]+(-[0-9]+)?,)*([0-9]+(-[0-9]+)?)$ ]]; then
        WARN "  Enter valid port(s)"
        return
    fi
    clear
    INFO "-- Service Detection --"
    sudo nmap "$1" -p "$PORT" -n -Pn -sV --version-intensity 6 --script banner -T4 -vv
    read -rp "Press any key to return to the main menu..."
}

MENU "$@"
