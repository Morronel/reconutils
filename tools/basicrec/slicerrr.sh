slice_url() {
	        local url=$1
		        while [[ $url =~ \/ ]]; do
				            if [[ "$url" != "https:/" && "$url" != "http:" && "$url" != "http:/" ]]; then
						                    echo "$url"
								                fi
										            url="${url%/*}"
											            done
											    }

											    export -f slice_url

											    while read -r line; do slice_url "$line"; done < katanaout.txt | anew katanasliced.txt

