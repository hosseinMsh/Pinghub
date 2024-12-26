#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 [-s <start_ip> -e <end_ip>] [-r <exclude_pattern>] -f <file_type>"
    echo
    echo "Options:"
    echo "  -s, --start <start_ip>         Starting IP address (e.g., 127.0.0.1)"
    echo "  -e, --end <end_ip>             Ending IP address (e.g., 127.0.10.255)"
    echo "  -r, --exclude <exclude_pattern> IP pattern to exclude (e.g., 127.0.1.*)"
    echo "  -f, --file_type <csv/txt>      Output file type (default: txt)"
    echo "  --run-bg                       Run in the background"
    echo "  --scan-ports <important/all>   Scan important ports (e.g., 22, 80) or all ports"
    echo "  --resolve-hostname             Resolve hostnames for IP addresses"
    echo "  --resolve-url <url>            Resolve a URL or domain to its IP address"
    echo "  --check-ssl                    Check SSL certificate expiration for responding IPs"
    echo "  -v, --view                     View the status of all IPs"
    echo "  -h, --help                     Show this help message"
    exit 0
}

# Default values
start_ip=""
end_ip=""
exclude_pattern="127.0.0.256"
file_type="txt"
max_parallel_jobs=100  # Max number of parallel jobs
output_file="output.txt"
tmp_output_file="tmp_output.txt"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--start) start_ip="$2"; shift ;;
        -e|--end) end_ip="$2"; shift ;;
        -r|--exclude) exclude_pattern="$2"; shift ;;
        -f|--file_type) file_type="$2"; shift ;;
        -h|--help) show_help ;;
        *) echo "Unknown parameter passed: $1"; show_help ;;
    esac
    shift
done

# Validate input
if [[ -z "$start_ip" || -z "$end_ip" ]]; then
    echo "Error: You must provide both a start and end IP address."
    exit 1
fi

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
        echo "$ip,responded" >> "$tmp_output_file"
    else
        echo "$ip,unreachable" >> "$tmp_output_file"
    fi
}

# Function to scan IPs with parallelism
scan_ips_in_parallel() {
    local start_ip="$1"
    local end_ip="$2"
    local exclude_pattern="$3"
    
    local ip_list=()
    while read -r ip; do
        # Exclude IPs that match the exclusion pattern
        if matches_exclusion "$ip" "$exclude_pattern"; then
            echo "Skipping $ip (matches exclusion pattern)"
            continue
        fi
        ip_list+=("$ip")
    done < <(seq $(ip_to_int "$start_ip") $(ip_to_int "$end_ip") | while read i; do int_to_ip $i; done)

    # Process IPs in parallel
    echo "Scanning IPs in parallel..."
    for ip in "${ip_list[@]}"; do
        ((job_count++))
        (
            ping_ip "$ip"
        ) &

        # Limit parallel jobs
        if ((job_count >= max_parallel_jobs)); then
            wait -n  # Wait for any job to finish
            ((job_count--))
        fi
    done

    wait  # Wait for all jobs to finish
}

# Batch write the results to the output file
batch_write_output() {
    cat "$tmp_output_file" >> "$output_file"
    rm "$tmp_output_file"
}

# Call the function to scan IPs
scan_ips_in_parallel "$start_ip" "$end_ip" "$exclude_pattern"

# Batch write the results
batch_write_output
echo "IP scanning complete. Results saved to $output_file"
