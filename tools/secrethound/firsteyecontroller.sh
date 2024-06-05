#!/bin/bash

# Path to your original script
ORIGINAL_SCRIPT="/root/lukefuzzer/myrec/script/secreteye/mysecrethound.sh"

# Path to your file containing the wildcards
WILDCARDS_FILE="/root/lukefuzzer/myrec/script/secreteye/input.txt"

# Temp file to keep track of already processed domains
PROCESSED_FILE="/root/lukefuzzer/myrec/script/secreteye/processed.txt"

echo "Started Th3 ey3! Beware!" | notify -id the-eye-flow

# Get the next unprocessed domain
get_next_domain() {
	while read -r line; do
		if ! grep -q "$line" "$PROCESSED_FILE"; then
			echo "$line" >> "$PROCESSED_FILE"
			echo "$line"
			return
		fi
	done < "$WILDCARDS_FILE"
}

while true; do
		# Load is low, so spawn another instance
		NEXT_DOMAIN=$(get_next_domain)

		if [ -n "$NEXT_DOMAIN" ]; then
			echo "Spawning new instance for domain $NEXT_DOMAIN" | notify -id the-eye-flow,the-eye-verbose
			bash "$ORIGINAL_SCRIPT" "$NEXT_DOMAIN"
		else
			echo "No more domains left. Good job!" | notify -id the-eye-flow,the-eye-verbose
			break
		fi

	# Wait a minute before checking again
	sleep 60
done
