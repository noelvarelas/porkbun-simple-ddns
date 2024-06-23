#!/bin/bash

# YOUR DOMAIN INFO HERE
domain="example.com"
subdomain="subdomain"

# YOUR API KEYS HERE
apikey="pk1_yourapikey"
secretapikey="sk1_yoursecretapikey"

# URI Endpoints
url_get_v4="https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/$domain/A/$subdomain"
url_get_v6="https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/$domain/AAAA/$subdomain"
url_edit_v4="https://api.porkbun.com/api/json/v3/dns/editByNameType/$domain/A/$subdomain"
url_edit_v6="https://api.porkbun.com/api/json/v3/dns/editByNameType/$domain/AAAA/$subdomain"

# Get Current IP Addresses
ipv4addr=$(curl -s -4 ip.me)
echo "Current IPv4 address: $ipv4addr"
ipv6addr=$(curl -s -6 ip.me)
echo "Current IPv6 address: $ipv6addr"

# API Commands
api_get="{\"apikey\": \"$apikey\", \"secretapikey\": \"$secretapikey\"}"
api_edit_v4="{\"apikey\": \"$apikey\", \"secretapikey\": \"$secretapikey\", \"content\": \"$ipv4addr\"}"
api_edit_v6="{\"apikey\": \"$apikey\", \"secretapikey\": \"$secretapikey\", \"content\": \"$ipv6addr\"}"

# Get Existing IPv4 Record
get_ipv4record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_get" "$url_get_v4")
ipv4record=$(echo "$get_ipv4record" | jq -r '.records[0].content')
echo "Existing IPv4 DNS record: $ipv4record"

# Get Existing IPv6 Record
get_ipv6record=$(curl -s -X POST -H "Content-Type: application/json" -d "$api_get" "$url_get_v6")
ipv6record=$(echo "$get_ipv6record" | jq -r '.records[0].content')
echo "Existing IPv6 DNS record: $ipv6record"

# Update IPv4 Record
if [ "$ipv4addr" != "$ipv4record" ]; then
  echo "IPv4 address changed. Updating record..."
  curl -s -X POST -H "Content-Type: application/json" -d "$api_edit_v4" "$url_edit_v4"; echo
  date >> porkbun.log
  echo "DNS A record changed from $ipv4record to $ipv4addr" >> porkbun.log
else
  echo "No IPv4 update necessary."
fi

# Update IPv6 Record
if [ "$ipv6addr" != "$ipv6record" ]; then
  echo "IPv6 address changed. Updating record..."
  curl -s -X POST -H "Content-Type: application/json" -d "$api_edit_v6" "$url_edit_v6"; echo
  date >> porkbun.log
  echo "DNS AAAA record changed from $ipv6record to $ipv6addr" >> porkbun.log
else
  echo "No IPv6 update necessary."
fi
