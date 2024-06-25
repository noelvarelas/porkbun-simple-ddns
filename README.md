## porkbun-simple-ddns
This is a simple Bash script for Linux that automatically keeps your Porkbun A and AAAA DNS records updated using the Porkbun API.
It's meant for people with dynamic IP addresses that want to self-host a server using a domain name from Porkbun.
There is no complicated installation, no containers to set up, etc. Just put your info in the script and run it with a cron job.
It's pretty self-explanatory, but a configuration and cron example is included here for any Linux beginners.

### Instructions
1. Create your Porkbun API keys at https://porkbun.com/account/api
2. Toggle on "API Access" for your domain at https://porkbun.com/account/domains
3. On the same page, create the DNS records for the machine you want to use. This script only updates existing records.
4. Make sure `curl` and `jq` are installed on your machine. Run `sudo apt install curl jq` or your distro's equivalent.
5. Download the script to your machine, edit it with your configuration info at the top of the script.
6. Make sure the script is executable by running `chmod +x porkbun-simple-ddns.sh`.
7. Make a cron job to run the script periodically.

### Configuration Example
Here's a configuration example for a machine that will be using the domain `cats.example.com`.
This machine uses IPv4 but doesn't use IPv6, so we will update the `A` record but disable the `AAAA` record.
The default TTL (time to live) for Porkbun is 600, so we will leave that alone as we have no reason to change it.
We will copy and paste in the two API keys from Porkbun's API page linked above in step 1.
```
readonly DOMAIN="example.com"
readonly SUBDOMAIN="cats"
readonly TTL="600"
readonly UPDATE_A="true"
readonly UPDATE_AAAA="false"
readonly APIKEY="pk1_4l0ng5tr1ng0fnumb3r54nd13tt3r54l0ng5tr1ng0fnumb3r54nd13tt3r5"
readonly SECRETAPIKEY="sk1_4l0ng5tr1ng0fnumb3r54nd13tt3r54l0ng5tr1ng0fnumb3r54nd13tt3r5"
```
If we wanted to update `example.com` itself with no subdomain, the subdomain setting would be left empty like this: `readonly SUBDOMAIN=""`

### Cron Job Example
For this example, we'll place the script in our home folder, so it will be at `~/porkbun-simple-ddns.sh`.
We will create a cron job that runs the script every 5 minutes and keeps the result of the last time it ran in a file at `~/porkbun-cron.log`
1. Run `crontab -e`
2. Arrow down to the bottom of the file, and copy and paste this in at the bottom:
```
3-59/5 * * * * ~/porkbun-simple-ddns.sh > ~/porkbun-cron.log
```
3. Save the file and exit. (if you're using nano: ctrl+o and enter to save, ctrl+x to exit)
4. You can run `cat ~/porkbun-cron.log` and see the results of the last automatic update. It won't be there if you check immediately after setting it up, so give it at least five minutes.

### (Optional) Changelog Setup
If you want a long-term changelog so that later on you can see all the times your machine had to change its DNS record, you can turn this feature on in the script. By default it will save to `~/porkbun.log`, but the location is configurable.
```
# Optional external log file that only updates if a record actually changes
readonly ENABLE_CHANGELOG="true"
readonly CHANGELOG_FILE="$HOME/porkbun.log"
```
