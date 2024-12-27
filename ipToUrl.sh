#!/bin/bash
#todo
# Define input and output file names
input_file="$1"
output_file="${1%.csv}_processed.csv"

# Check if input file is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <input_csv>"
    exit 1
fi

# Extract and process the data, keeping the original structure
awk -F',' 'BEGIN { OFS="," }
NR == 1 { print $0 }
NR > 1 {
    ip = $1; url = $3; domain = $4;
    print ip, $2, url, domain, $5, $6
}' "$input_file" > "$output_file"

echo "Processed data saved to $output_file"
