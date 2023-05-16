#!/bin/bash

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}=============================${RESET}"
echo -e "${RED}Running Privilege Check${RESET}"
echo -e "${CYAN}=============================${RESET}"
# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root.${RESET}"
    exit 1
fi

# Continue with the rest of the script as root
echo -e "${GREEN}Running as root. Performing privileged operations...${RESET}"

# Update & Upgrade
echo -e "${CYAN}=============================${RESET}"
echo -e "${GREEN}Updating & Upgrading Server${RESET}"
echo -e "${CYAN}=============================${RESET}"
apt update
apt upgrade -y

# Install Tools
echo -e "${CYAN}=============================${RESET}"
echo -e "${GREEN}Installing Required Tools${RESET}"
echo -e "${CYAN}=============================${RESET}"
apt install bind9 bind9utils bind9-doc -y

# Editing Options File
echo -e "${CYAN}=============================${RESET}"
echo -e "${GREEN}Editing Options File${RESET}"
echo -e "${CYAN}=============================${RESET}"
# Content to be added to named.conf.options
options_content='
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    dnssec-validation auto;
    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
};'

# Save the content to a temporary file
temp_file=$(mktemp)
echo "$options_content" > "$temp_file"

# Override the named.conf.options file
mv "$temp_file" /etc/bind/named.conf.options


# Editing Config File
echo -e "${CYAN}=============================${RESET}"
echo -e "${GREEN}Editing Config File${RESET}"
echo -e "${CYAN}=============================${RESET}"
# Ask user for the domain name
echo "Enter the domain name:"
read domain

# Content to be added
content="zone \"$domain\" {
    type master;
    file \"/etc/bind/db.$domain\";
};"

# Append content to named.conf.local file
echo "$content" | sudo tee -a /etc/bind/named.conf.local > /dev/null


# Creating Zone File
echo -e "${CYAN}=============================${RESET}"
echo -e "${GREEN}Creating Zone File${RESET}"
echo -e "${CYAN}=============================${RESET}"
# Ask user for the domain name
echo "Enter the domain name:"
read domain

# Ask user for the IP address
echo "Enter the IP address:"
read ip

# Content to be added
content="\$TTL    604800
@       IN      SOA     ns1.$domain. admin.$domain. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$domain.
@       IN      A       $ip
ns1     IN      A       $ip"

# Write content to db.example.com file
echo "$content" | sudo tee /etc/bind/db.$domain > /dev/null


# Adding Firewall Rules
# echo -e "${CYAN}=============================${RESET}"
# echo -e "${GREEN}Adding Required Firewall Rules (tcp: 53)${RESET}"
# echo -e "${CYAN}=============================${RESET}"
# iptables -I INPUT 6 -m state --state NEW -p tcp --dport 53 -j ACCEPT
# netfilter-persistent save

# Restart Service
systemctl restart bind9

# Creating Zone File
echo -e "${CYAN}=============================${RESET}"
echo -e "${GREEN}Add your records to /etc/bind/db.{your-domain} file and reload the service${RESET}"
echo -e "${GREEN}Done. Enjoy${RESET}"
echo -e "${CYAN}=============================${RESET}"
