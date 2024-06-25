#!/bin/bash

# INPUT YOUR INFORMATION HERE (Leave subdomain empty to edit root domain)
domain="example.com"
subdomain=""
ttl="600"
update_A="true"
update_AAAA="true"
apikey="pk1_yourapikeyhere"
secretapikey="sk1_yoursecretapikeyhere"

# Optional external log file that only updates if a record actually changes
enable_changelog="false"
changelog_file="$HOME/porkbun.log"

################ NO NEED TO EDIT ANYTHING BELOW THIS LINE ################

# Dependency Checks
if ! command -v curl &> /dev/null; then
  echo "curl is required but not installed."
  exit 1
fi
if ! command -v jq &> /dev/null; then
  echo "jq is required but not installed."
  exit 1
fi

# Timestamp and Domain
if [ "$subdomain" == "" ]; then
  fulldomain="$domain"
else
  fulldomain="$subdomain.$domain"
fi
date; echo "My domain: $fulldomain"

# Get Current IP Addresses
if [ "$update_A" == "true" ]; then
  ipv4_address=$(curl -s -4 https://ip.me)
  if [ $? -ne 0 ]; then
    echo "Failed to get current IPv4 address."
    exit 1
  fi
  echo "Current IPv4 address: $ipv4_address"
fi
if [ "$update_AAAA" == "true" ]; then
  ipv6_address=$(curl -s -6 https://ip.me)
  if [ $? -ne 0 ]; then
    echo "Failed to get current IPv6 address."
    exit 1
  fi
  echo "Current IPv6 address: $ipv6_address"
fi
if [ "$update_A" != "true" ] && [ "$update_AAAA" != "true" ]; then
  echo "A and AAAA record editing are both disabled in this script's config!"
  echo 'Set update_A and/or update_AAAA to "true" in this script.'
  exit 1
fi

# Porkbun URI Endpoints
url_get_A="https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/$domain/A/$subdomain"
url_get_AAAA="https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/$domain/AAAA/$subdomain"
url_edit_A="https://api.porkbun.com/api/json/v3/dns/editByNameType/$domain/A/$subdomain"
url_edit_AAAA="https://api.porkbun.com/api/json/v3/dns/editByNameType/$domain/AAAA/$subdomain"

# Porkbun API Commands
api_get="{\"apikey\": \"$apikey\", \"secretapikey\": \"$secretapikey\"}"
api_edit_A="{\"apikey\": \"$apikey\", \"secretapikey\": \"$secretapikey\", \"content\": \"$ipv4_address\", \"ttl\": \"$ttl\"}"
api_edit_AAAA="{\"apikey\": \"$apikey\", \"secretapikey\": \"$secretapikey\", \"content\": \"$ipv6_address\", \"ttl\": \"$ttl\"}"

# Get Existing IPv4 A Record
if [ "$update_A" == "true" ]; then
  full_A_record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_get" "$url_get_A")
  if [ $(echo $full_A_record | jq '.status') != '"SUCCESS"' ]; then
    echo "API request to get existing A record failed."
    exit 1
  fi
  if [ $(echo $full_A_record | jq '.records[0].content') == "null" ]; then
    echo "DNS A record does not exist for $fulldomain."
    echo 'Please either create one on Porkbun or set update_A="false" in this script.'
    exit 1
  fi
  A_record=$(echo "$full_A_record" | jq -r '.records[0].content')
  echo "Existing DNS A record: $A_record"
fi

# Get Existing IPv6 AAAA Record
if [ "$update_AAAA" == "true" ]; then
  full_AAAA_record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_get" "$url_get_AAAA")
  if [ $(echo $full_AAAA_record | jq '.status') != '"SUCCESS"' ]; then
    echo "API request to get existing AAAA record failed."
    exit 1
  fi
  if [ $(echo $full_AAAA_record | jq '.records[0].content') == "null" ]; then
    echo "DNS AAAA record does not exist for $fulldomain."
    echo 'Please either create one on Porkbun or set update_AAAA="false" in this script.'
    exit 1
  fi 
  AAAA_record=$(echo "$full_AAAA_record" | jq -r '.records[0].content')
  echo "Existing DNS AAAA record: $AAAA_record"
fi

# Update IPv4 A Record
A_changed="false"
if [ "$update_A" == "true" ]; then
  if [ "$ipv4_address" != "$A_record" ]; then
    edit_A_record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_edit_A" "$url_edit_A")
    if [ $(echo $edit_A_record | jq '.status') != '"SUCCESS"' ]; then
      echo "API request to edit A record failed."
      exit 1
    fi
    echo "DNS A record changed from $A_record to $ipv4_address"
    A_changed="true"
  else
    echo "No DNS A record update necessary."
  fi
fi

# Update IPv6 AAAA Record
AAAA_changed="false"
if [ "$update_AAAA" == "true" ]; then
  if [ "$ipv6_address" != "$AAAA_record" ]; then
    edit_AAAA_record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_edit_AAAA" "$url_edit_AAAA")
    if [ $(echo $edit_AAAA_record | jq '.status') != '"SUCCESS"' ]; then
      echo "API request to edit AAAA record failed."
      exit 1
    fi
    echo "DNS AAAA record changed from $AAAA_record to $ipv6_address"
    AAAA_changed="true"
  else
    echo "No DNS AAAA record update necessary."
  fi
fi

# Write to External Log (If Enabled)
if [ "$enable_changelog" == "true" ] && ([ "$A_changed" == "true" ] || [ "$AAAA_changed" == "true" ]); then
  [ -f "$changelog_file" ] || touch "$changelog_file"
  date >> $changelog_file
  if [ "$A_changed" == "true" ]; then
    echo "DNS A record for $fulldomain changed from $A_record to $ipv4_address" >> $changelog_file
  fi
  if [ "$AAAA_changed" == "true" ]; then
    echo "DNS AAAA record for $fulldomain changed from $AAAA_record to $ipv6_address" >> $changelog_file
  fi
  echo >> $changelog_file
fi
