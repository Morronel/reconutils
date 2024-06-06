#!/bin/bash

if [ "$#" -ne 1 ]; then
	    echo "Usage: $0 <domain>"
	    exit 1
fi

DOMAIN=$1

echo "Running subenum on $DOMAIN domain..." | notify
mkdir $DOMAIN
mkdir $DOMAIN/subs
cd ./$DOMAIN/subs
echo "Starting amass intel..." | notify
amass intel -active -d "$DOMAIN" -whois | anew amassintel1.txt
echo "found $(cat amassintel1.txt | wc -l) subs with amass intel. Starting amass enum..." | notify
timeout 3h amass enum -active -d "$DOMAIN" -o amass_active_results.txt
echo "found $(cat amass_active_results.txt | wc -l) subs with active amass enum. Starting passive amass enum..." | notify
amass enum --passive -d "$DOMAIN" > amass_passive_results.txt
echo "found $(cat amass_passive_results.txt | wc -l) subs with passive amass enum. Starting subfinder..." | notify
subfinder -d "$DOMAIN" -o subfinder_subs.txt
echo "found $(cat subfinder_subs.txt | wc -l) subs with subfinder. Starting assetfinder..." | notify
assetfinder "$DOMAIN" > assetfinder_subdomains.txt
echo "found $(cat assetfinder_subdomains.txt | wc -l) subs with assetfinder. Starting uncover..." | notify
uncover -q "$DOMAIN" -f host > uncover_subs.txt
echo "found $(cat uncover_subs.txt | wc -l) subs with uncover. Starting dns bruteforcing..." | notify
dnsx -d "$DOMAIN" -r /root/lukefuzzer/resolvers/resolvers.txt -w ../../words/dns-Jhaddix.txt > dnsxbrutewordlist.txt
echo "found $(cat dnsxbrutewordlist.txt | wc -l) subs with brute force. Starting csprecon..." | notify
csprecon -u "$DOMAIN" > cspreconsublist.txt
echo "found $(cat cspreconsublist.txt | wc -l) subs with csprecon. Calculating total subs..." | notify

cat subfinder_subs.txt | anew rootsubs.txt
cat dnsxbrutewordlist.txt | anew rootsubs.txt
cat amass_passive_results.txt | anew rootsubs.txt
cat uncover_subs.txt | anew rootsubs.txt
cat assetfinder_subdomains.txt | anew rootsubs.txt
cat amass_active_results.txt | anew rootsubs.txt
cat rootsubs.txt | grep "$DOMAIN" > filteredsubs.txt
cat filteredsubs.txt | awk '!/\*/' > filteredsubs2.txt
echo "found $(cat filteredsubs2.txt | wc -l) subs total. For now..." | notify


cat filteredsubs2.txt | httpx -ip -o ips1.txt
awk -F'[\\[\\]]' '{print $2}' ips1.txt | anew > stripped_ips.txt
cat stripped_ips.txt | while read -r ip; do asnmap -i $ip; done | anew >> asnmapoutput.txt
echo "found $(cat asnmapoutput.txt | wc -l) ip ranges from asnmap. Starting hednsextractor" | notify
cat asnmapoutput.txt | while read -r iprange; do hednsextractor -target $iprange; done >> hednsextractoroutput1.txt 2>&1
cat hednsextractoroutput1.txt | grep "$DOMAIN" > hednsexrelevant.txt
echo "found $(cat hednsexrelevant.txt | wc -l) subs from hednsextractor!" | notify
for i in $(cat filteredsubs2.txt); do nslookup $i | awk '/Address: / {print $2}' | hednsextractor -silent -only-domains >> ptr_records.txt; done
cat ptr_records.txt | grep "$DOMAIN" | anew filteredsubs2.txt
cat hednsexrelevant.txt | anew filteredsubs2.txt
echo "found $(cat ptr_records.txt | wc -l) ptr records and $(cat hednsexrelevant.txt | wc -l) more subs with hednsextractor and ptr records tricks. Also, found $(cat stripped_ips.txt | wc -l) ip addresses. Starting subdomain takeover checks" | notify
python3 /root/lukefuzzer/dnsReaper/main.py file --filename ./filteredsubs2.txt --out reapertakeover.txt
echo "We found $(cat reapertakeover.txt | wc -l) subdomain takeovers, starting portscan" | notify

naabu -l stripped_ips.txt -p 8080,10000,20000,2222,7080,9009,7443,2087,2096,8443,4100,2082,2083,2086,9999,2052,9001,9002,7000,7001,8082,8084,8085,8010,9000,2078,2080,2079,2053,2095,4000,5280,8888,9443,5800,631,8000,8008,8087,84,85,86,88,10125,9003,7071,8383,7547,3434,10443,8089,3004,81,4567,7081,82,444,1935,3000,9998,4433,4431,4443,83,90,8001,8099,300,591,593,832,981,1010,1311,2480,3128,3333,4243,4711,4712,4993,5000,5104,5108,6543,7396,7474,8014,8042,8069,8081,8088,8090,8091,8118,8123,8172,8222,8243,8280,8281,8333,8500,8834,8880,8983,9043,9060,9080,9090,9091,9200,9800,9981,12443,16080,18091,18092,20720,28017 -o naabu_output.txt
echo "found $(cat naabu_output.txt | wc -l) non-standard ports open. Finishing for now..." | notify
cat naabu_output.txt | awk -F: '{if ($2 == "443") print "https://"$1":"$2; else if ($2 == "80") print "http://"$1":"$2; else print "http://"$1":"$2}' | httpx -probe -sc -title -cl > httpxfromips.txt
cat httpxfromips.txt | awk '/FAILED/ {gsub("https://", "", $1); gsub("http://", "", $1); split($1, a, ":"); print a[1]}' | sort -u | xargs -I % nmap -sV % >> nmapoutput.txt

cat filteredsubs2.txt | httpx -sc -title -cl -fr -o alivestandard.txt
echo "found $(cat alivestandard.txt | wc -l) alive web apps on standard ports." | notify

cd ../..
mkdir ./$DOMAIN/urls
cd ./$DOMAIN/urls
echo "starting active discovery on $DOMAIN domain!" | notify
cat ../subs/alivestandard.txt | awk '{print $1}' > readyforenum.txt
katana -list readyforenum.txt -output katanaout.txt -jc
echo "found $(cat katanaout.txt | wc -l) urls with katana, going for GAU" | notify
cat readyforenum.txt | gau | anew gau_output.txt
echo "found $(cat gau_output.txt | wc -l) urls with GAU, going to search for secrets in JS" | notify
cat gau_output.txt | grep "\.js" | anew jslist.txt
cat katanaout.txt | grep "\.js" | anew jslist.txt
nuclei -l jslist.txt -t /root/nuclei-templates/http/exposures/tokens -tags exposure,tokens | notify
#echo "that's it for secrets search, going to parameter discovery" | notify
#bash ../../slicerrr.sh
#echo "Started with x8!" | notify
#x8 -u katanasliced.txt -w /root/lukefuzzer/SecLists/Discovery/Web-Content/burp-parameter-names.txt -o x8output.txt
#echo "Done with x8!" | notify
echo "thats it for now!" | notify
