#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 [-s <start_ip> -e <end_ip>] [-r <exclude_pattern>] -f <file_name>"
    echo
    echo "Options:"
    echo "  -s, --start <start_ip>         Starting IP address (e.g., 192.168.1.1)"
    echo "  -e, --end <end_ip>             Ending IP address (e.g., 192.168.1.255)"
    echo "  -r, --exclude <exclude_pattern> IP pattern to exclude (e.g., 192.168.1.5)"
    echo "  -f, --file_name <name>          Output file name (without extension, will be .csv)"
    echo "  -h, --help                     Show this help message"
    exit 0
}

# Default values
start_ip=""
end_ip=""
exclude_pattern=""
file_name=""
max_parallel_jobs=50  # Reduced number of parallel jobs for testing

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
echo "ips,Ping Test,urls,domain,SSL certificate expiration,ports" > "$output_file"
echo "ips" > "$non_responsive_file"

# Function to convert IP to integer
ip_to_int() {
    local ip="$1"
    local a b c d
    IFS=. read -r a b c d <<< "$ip"
    echo "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

# Function to convert integer to IP
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

# Function to generate IP range
generate_ip_range() {
    local start_ip="$1"
    local end_ip="$2"
    local exclude_pattern="$3"

    for ((i=$(ip_to_int "$start_ip"); i<=$(ip_to_int "$end_ip"); i++)); do
        local ip=$(int_to_ip "$i")
        if matches_exclusion "$ip" "$exclude_pattern"; then
            continue
        fi
        echo "$ip"
    done
}

# Process IPs in parallel
generate_ip_range "$start_ip" "$end_ip" "$exclude_pattern" | xargs -I {} -P "$max_parallel_jobs" bash -c '
    ip="$1"
    output_file="$2"
    non_responsive_file="$3"

    if /bin/ping -c 3 -W 5 "$ip" > /tmp/ping_output 2>&1; then
        min_ping=$(grep -oP "min/avg/max/mdev = \K[0-9.]+" /tmp/ping_output | head -n 1)
        echo "$ip,$min_ping,,,," >> "$output_file"  # Write responsive IP with min ping time to output file
    else
        echo "$ip" >> "$non_responsive_file"  # Write non-responsive IP to separate file
    fi
' _ {} "$output_file" "$non_responsive_file"

# Output results
echo "IP scanning complete. Results saved to $output_file and $non_responsive_file."
