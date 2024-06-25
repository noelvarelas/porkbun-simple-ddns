#!/bin/bash

# Porkbun dynamic DNS updater using the Porkbun API

# USER CONFIGURATION (Leave subdomain empty to edit the root domain)
readonly DOMAIN="example.com"
readonly SUBDOMAIN=""
readonly TTL="600"
readonly UPDATE_A="true"
readonly UPDATE_AAAA="true"
readonly APIKEY="pk1_yourapikeyhere"
readonly SECRETAPIKEY="sk1_yoursecretapikeyhere"

# Optional external log file that only updates if a record actually changes
readonly ENABLE_CHANGELOG="false"
readonly CHANGELOG_FILE="$HOME/porkbun.log"

################ NO NEED TO EDIT ANYTHING BELOW THIS LINE ################

# Dependency Checks
if ! command -v curl &> /dev/null; then
  echo "ERROR: curl is required but not installed."
  exit 1
fi
if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required but not installed."
  exit 1
fi

# Timestamp and Domain
if [ "$SUBDOMAIN" == "" ]; then
  fulldomain="$DOMAIN"
else
  fulldomain="$SUBDOMAIN.$DOMAIN"
fi
date; echo "My domain: $fulldomain"

# Get Current IP Addresses
if [ "$UPDATE_A" == "true" ]; then
  ipv4_address=$(curl -s -4 https://ip.me)
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get current IPv4 address."
    exit 1
  fi
  echo "Current IPv4 address: $ipv4_address"
fi
if [ "$UPDATE_AAAA" == "true" ]; then
  ipv6_address=$(curl -s -6 https://ip.me)
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get current IPv6 address."
    exit 1
  fi
  echo "Current IPv6 address: $ipv6_address"
fi
if [ "$UPDATE_A" != "true" ] && [ "$UPDATE_AAAA" != "true" ]; then
  echo "ERROR: A and AAAA record editing are both disabled in this script's config!"
  exit 1
fi

# Porkbun URI Endpoints
api_uri_get_a="https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/$DOMAIN/A/$SUBDOMAIN"
api_uri_get_aaaa="https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/$DOMAIN/AAAA/$SUBDOMAIN"
api_uri_edit_a="https://api.porkbun.com/api/json/v3/dns/editByNameType/$DOMAIN/A/$SUBDOMAIN"
api_uri_edit_aaaa="https://api.porkbun.com/api/json/v3/dns/editByNameType/$DOMAIN/AAAA/$SUBDOMAIN"

# Porkbun API Commands
api_cmd_get="{\"APIKEY\": \"$APIKEY\", \"SECRETAPIKEY\": \"$SECRETAPIKEY\"}"
api_cmd_edit_a="{\"APIKEY\": \"$APIKEY\", \"SECRETAPIKEY\": \"$SECRETAPIKEY\", \"content\": \"$ipv4_address\", \"TTL\": \"$TTL\"}"
api_cmd_edit_aaaa="{\"APIKEY\": \"$APIKEY\", \"SECRETAPIKEY\": \"$SECRETAPIKEY\", \"content\": \"$ipv6_address\", \"TTL\": \"$TTL\"}"

# Get Existing IPv4 A Record
if [ "$UPDATE_A" == "true" ]; then
  full_a_record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_cmd_get" "$api_uri_get_a")
  if [ $(echo $full_a_record | jq '.status') != '"SUCCESS"' ]; then
    echo "ERROR: API request to get existing A record failed."
    exit 1
  fi
  if [ $(echo $full_a_record | jq '.records[0].content') == "null" ]; then
    echo "ERROR: DNS A record does not exist for $fulldomain."
    exit 1
  fi
  a_record=$(echo "$full_a_record" | jq -r '.records[0].content')
  echo "Existing DNS A record: $a_record"
fi

# Get Existing IPv6 AAAA Record
if [ "$UPDATE_AAAA" == "true" ]; then
  full_aaaa_record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_cmd_get" "$api_uri_get_aaaa")
  if [ $(echo $full_aaaa_record | jq '.status') != '"SUCCESS"' ]; then
    echo "ERROR: API request to get existing AAAA record failed."
    exit 1
  fi
  if [ $(echo $full_aaaa_record | jq '.records[0].content') == "null" ]; then
    echo "ERROR: DNS AAAA record does not exist for $fulldomain."
    exit 1
  fi
  aaaa_record=$(echo "$full_aaaa_record" | jq -r '.records[0].content')
  echo "Existing DNS AAAA record: $aaaa_record"
fi

# Update IPv4 A Record
a_changed="false"
if [ "$UPDATE_A" == "true" ]; then
  if [ "$ipv4_address" != "$a_record" ]; then
    edit_a_record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_cmd_edit_a" "$api_uri_edit_a")
    if [ $(echo $edit_a_record | jq '.status') != '"SUCCESS"' ]; then
      echo "ERROR: API request to edit A record failed."
      exit 1
    fi
    echo "DNS A record changed from $a_record to $ipv4_address"
    a_changed="true"
  else
    echo "No DNS A record update necessary."
  fi
fi

# Update IPv6 AAAA Record
aaaa_changed="false"
if [ "$UPDATE_AAAA" == "true" ]; then
  if [ "$ipv6_address" != "$aaaa_record" ]; then
    edit_aaaa_record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_cmd_edit_aaaa" "$api_uri_edit_aaaa")
    if [ $(echo $edit_aaaa_record | jq '.status') != '"SUCCESS"' ]; then
      echo "ERROR: API request to edit AAAA record failed."
      exit 1
    fi
    echo "DNS AAAA record changed from $aaaa_record to $ipv6_address"
    aaaa_changed="true"
  else
    echo "No DNS AAAA record update necessary."
  fi
fi

# Write to External Log (if enabled)
if [ "$ENABLE_CHANGELOG" == "true" ] && ([ "$a_changed" == "true" ] || [ "$aaaa_changed" == "true" ]); then
  if [ ! -f "$CHANGELOG_FILE" ]; then
    touch "$CHANGELOG_FILE"
    if [ ! -f "$CHANGELOG_FILE" ]; then
      echo "ERROR: Could not create changelog file."
      exit 1
    fi
  fi
  date >> $CHANGELOG_FILE
  if [ "$a_changed" == "true" ]; then
    echo "DNS A record for $fulldomain changed from $a_record to $ipv4_address" >> $CHANGELOG_FILE
  fi
  if [ "$aaaa_changed" == "true" ]; then
    echo "DNS AAAA record for $fulldomain changed from $aaaa_record to $ipv6_address" >> $CHANGELOG_FILE
  fi
  echo >> $CHANGELOG_FILE
fi
