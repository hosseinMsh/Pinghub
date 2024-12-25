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
exclude_pattern=""
file_type="txt"
view=false
run_in_bg=false
scan_ports=""
resolve_hostname=false
resolve_url=""
check_ssl=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--start) start_ip="$2"; shift ;;
        -e|--end) end_ip="$2"; shift ;;
        -r|--exclude) exclude_pattern="$2"; shift ;;
        -f|--file_type) file_type="$2"; shift ;;
        --run-bg) run_in_bg=true ;;
        --scan-ports) scan_ports="$2"; shift ;;
        --resolve-hostname) resolve_hostname=true ;;
        --resolve-url) resolve_url="$2"; shift ;;
        --check-ssl) check_ssl=true ;;
        -v|--view) view=true ;;
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

# Function to generate all IPs in a range
generate_ips_in_range() {
    local start_ip="$1"
    local end_ip="$2"
    
    # Convert start and end IP to integers for comparison
    local start_num=$(ip_to_int "$start_ip")
    local end_num=$(ip_to_int "$end_ip")
    
    local ip_list=()
    for ((i=start_num; i<=end_num; i++)); do
        ip_list+=("$(int_to_ip $i)")
    done
    
    echo "${ip_list[@]}"
}

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
    
    # Remove any trailing '*' from the pattern and replace with regex
    pattern="${pattern//\*/.*}"
    
    if [[ "$ip" =~ $pattern ]]; then
        return 0  # Match
    else
        return 1  # No match
    fi
}

# Function to ping IPs and perform actions
ping_ips_in_range() {
    local start_ip="$1"
    local end_ip="$2"
    local exclude_pattern="$3"
    
    # Generate IPs in range
    ips=($(generate_ips_in_range "$start_ip" "$end_ip"))
    
    for ip in "${ips[@]}"; do
        # Check if the IP matches the exclusion pattern
        if matches_exclusion "$ip" "$exclude_pattern"; then
            echo "Skipping $ip (matches exclusion pattern)"
            continue
        fi
        
        # Ping the IP
        if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
            echo "$ip,responded"
            # You can add other actions here like port scanning, resolving hostname, etc.
        else
            echo "$ip,unreachable"
        fi
    done
}

# Call the function to ping IPs in range
ping_ips_in_range "$start_ip" "$end_ip" "$exclude_pattern"
