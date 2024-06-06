#!/bin/bash

if [ "$#" -ne 1 ]; then
            echo "Usage: $0 <domain>"
            exit 1
fi

DOMAIN=$1

BASE_DIR="$(pwd)/scanResults/${DOMAIN}"

echo "Running subenum on ${DOMAIN} domain..." | notify -id the-eye-verbose
mkdir -p "${BASE_DIR}/subs"
cd "${BASE_DIR}/subs"
echo "Starting passive amass enum on ${DOMAIN}..." | notify -id the-eye-verbose
timeout 1h amass enum --passive -d "${DOMAIN}" > amass_passive_results.txt
echo "found $(cat amass_passive_results.txt | wc -l) subs with passive amass enum. Starting subfinder on ${DOMAIN}..." | notify -id the-eye-verbose
subfinder -d "${DOMAIN}" -o subfinder_subs.txt
echo "found $(cat subfinder_subs.txt | wc -l) subs with subfinder. Starting assetfinder on $DOMAIN... " | notify -id the-eye-verbose
assetfinder "$DOMAIN" > assetfinder_subdomains.txt
echo "found $(cat assetfinder_subdomains.txt | wc -l) subs with assetfinder. Starting uncover on $DOMAIN..." | notify -id the-eye-verbose
uncover -q "$DOMAIN" -f host > uncover_subs.txt
echo "found $(cat uncover_subs.txt | wc -l) subs with uncover. Starting csp recon on $DOMAIN" | notify -id the-eye-verbose
csprecon -u "$DOMAIN" > cspreconsublist.txt
echo "found $(cat cspreconsublist.txt | wc -l) subs with csprecon. Calculating total subs on $DOMAIN..." | notify -id the-eye-verbose

cat subfinder_subs.txt | anew rootsubs.txt
cat amass_passive_results.txt | anew rootsubs.txt
cat uncover_subs.txt | anew rootsubs.txt
cat assetfinder_subdomains.txt | anew rootsubs.txt
cat rootsubs.txt | grep "$DOMAIN" > filteredsubs.txt
cat filteredsubs.txt | awk '!/\*/' > filteredsubs2.txt
#rm subfinder_subs.txt
#rm amass_passive_results.txt
#rm uncover_subs.txt
#rm assetfinder_subdomains.txt
#rm rootsubs.txt
#rm filteredsubs.txt
echo "found $(cat filteredsubs2.txt | wc -l) subs total on $DOMAIN. For now..." | notify -id the-eye-verbose

cat filteredsubs2.txt | httpx -sc -title -cl -fr -o alivestandard.txt
echo "found $(cat alivestandard.txt | wc -l) alive web apps on standard ports of $DOMAIN." | notify -id the-eye-verbose

mkdir -p "${BASE_DIR}/urls"
cd "${BASE_DIR}/urls"
echo "starting active discovery on $DOMAIN domain!" | notify -id the-eye-verbose,the-eye-flow
cat ../subs/alivestandard.txt | awk '{print $1}' > readyforenum.txt
katana -list readyforenum.txt -output katanaout.txt -jc
echo "found $(cat katanaout.txt | wc -l) urls with katana, going for GAU on $DOMAIN" | notify -id the-eye-verbose
cat readyforenum.txt | gau | anew gau_output.txt
echo "found $(cat gau_output.txt | wc -l) urls with GAU, going to search for secrets in JS on $DOMAIN" | notify -id the-eye-verbose
cat gau_output.txt | grep "\.js" | anew jslist.txt
cat katanaout.txt | grep "\.js" | anew jslist.txt
cat katanaout.txt | anew jslist.txt
cat katanaout.txt | anew highsearchlist.txt
cat gau_output.txt | grep "\?" | anew highsearchlist.txt
echo "found $(cat jslist.txt | wc -l) js/json files on $DOMAIN domain, starting nuclei on them" | notify -id the-eye-verbose
nuclei -l jslist.txt -t /root/nuclei-templates/http/exposures/tokens -tags exposure,tokens -o nucleisecrets.txt | notify -id the-eye-secrets
echo "found $(cat nucleisecrets.txt | wc -l) secrets with nuclei. Thats it for now on $DOMAIN , going to search for high/crit" | notify -id the-eye-verbose,the-eye-flow
nuclei -l highsearchlist.txt -s critical,high -o nucleihigh.txt | notify -id the-eye-secrets
echo "found $(cat nucleihigh.txt | wc -l) highs on $DOMAIN domain, going to finish" | notify -id the-eye-verbose,the-eye-flow
echo "finished with $DOMAIN url discovery!" | notify -id the-eye-verbose,the-eye-flow

