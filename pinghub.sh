#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 [-s <start_ip> -e <end_ip>] [-r <exclude_pattern>] -f <file_name>"
    echo
    echo "Options:"
    echo "  -s, --start <start_ip>         Starting IP address (e.g., 127.0.0.1)"
    echo "  -e, --end <end_ip>             Ending IP address (e.g., 127.0.10.255)"
    echo "  -r, --exclude <exclude_pattern> IP pattern to exclude (e.g., 127.0.1.*)"
    echo "  -f, --file_name <name>          Output file name (without extension, will be .csv)"
    echo "  -h, --help                     Show this help message"
    exit 0
}

# Default values
start_ip=""
end_ip=""
exclude_pattern=""
file_name=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--start) start_ip="$2"; shift ;;
        -e|--end) end_ip="$2"; shift ;;
        -r|--exclude) exclude_pattern="$2"; shift ;;
        -f|--file_name) file_name="$2"; shift ;;
        -h|--help) show_help ;;
        *) echo "Unknown parameter passed: $1"; show_help ;;
    esac
    shift
done

# Validate input
if [[ -z "$start_ip" || -z "$end_ip" || -z "$file_name" ]]; then
    echo "Error: You must provide a start IP, end IP, and file name for pinging."
    exit 1
fi

# Prepare output files
output_file="${file_name}.csv"
non_responsive_file="${file_name}-non_responsive.csv"

# Write headers to the output file
echo "ips,urls,domain,SSL certificate expiration,ports" > "$output_file"
echo "ips" > "$non_responsive_file"

# Convert IP to integer
ip_to_int() {
    local ip="$1"
    local a b c d
    IFS=. read -r a b c d <<< "$ip"
    echo "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

# Convert integer to IP
int_to_ip() {
    local int="$1"
    echo "$((int >> 24 & 255)).$((int >> 16 & 255)).$((int >> 8 & 255)).$((int & 255))"
}

# Function to check if an IP matches the exclusion pattern
matches_exclusion() {
    local ip="$1"
    local pattern="$2"
    pattern="${pattern//\*/.*}"  # Replace '*' with '.*' for regex
    if [[ "$ip" =~ $pattern ]]; then
        return 0  # Match
    else
        return 1  # No match
    fi
}

# Function to ping an IP
ping_ip() {
    local ip="$1"
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo "$ip,,," >> "$output_file"  # Write responsive IP to output file
    else
        echo "$ip" >> "$non_responsive_file"  # Write non-responsive IP to separate file
    fi
}

# Function to scan IPs in parallel
scan_ips_in_parallel() {
    local start_ip="$1"
    local end_ip="$2"
    local exclude_pattern="$3"

    local ip_list=()
    for ((i=$(ip_to_int "$start_ip"); i<=$(ip_to_int "$end_ip"); i++)); do
        local ip=$(int_to_ip "$i")
        # Exclude IPs that match the exclusion pattern
        if matches_exclusion "$ip" "$exclude_pattern"; then
            echo "Skipping $ip (matches exclusion pattern)"
            continue
        fi
        ip_list+=("$ip")
    done

    # Ping each IP in parallel
    echo "Pinging IPs in parallel..."
    printf "%s\n" "${ip_list[@]}" | xargs -n 1 -P 100 bash -c 'ping_ip "$@"' _  # Run ping_ip in parallel
}

# Call the function to scan IPs
scan_ips_in_parallel "$start_ip" "$end_ip" "$exclude_pattern"

# Output results
echo "IP scanning complete. Results saved to $output