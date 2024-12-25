#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 -b <base_ip> -s <start_range> -e <end_range> -f <file_type> [--run-bg] [--scan-ports important/all] [--resolve-hostname] [--resolve-url <url>] [--check-ssl] [-v]"
    echo
    echo "Options:"
    echo "  -b, --base_ip <base_ip>       Base IP address (e.g., 192.168.1)"
    echo "  -s, --start <start_range>     Start range (1-255)"
    echo "  -e, --end <end_range>         End range (1-255)"
    echo "  -f, --file_type <csv/txt>     Output file type (default: txt)"
    echo "  --run-bg                      Run in the background"
    echo "  --scan-ports <important/all>  Scan important ports (e.g., 22, 80) or all ports"
    echo "  --resolve-hostname            Resolve hostnames for IP addresses"
    echo "  --resolve-url <url>           Resolve a URL or domain to its IP address"
    echo "  --check-ssl                   Check SSL certificate expiration for responding IPs"
    echo "  -v, --view                    View the status of all IPs"
    echo "  -h, --help                    Show this help message"
    exit 0
}

# Default values
file_type="txt"
start_range=1
end_range=255
base_ip=""
view=false
run_in_bg=false
scan_ports=""
resolve_hostname=false
resolve_url=""
check_ssl=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -b|--base_ip) base_ip="$2"; shift ;;
        -s|--start) start_range="$2"; shift ;;
        -e|--end) end_range="$2"; shift ;;
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
if [[ ! "$base_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid base IP address. It should be in the format X.X.X (e.g., 192.168.1)"
    exit 1
fi

if [[ ! "$start_range" =~ ^[0-9]+$ || ! "$end_range" =~ ^[0-9]+$ || "$start_range" -gt "$end_range" ]]; then
    echo "Invalid range. Start and end ranges must be integers, and start must be less than or equal to end."
    exit 1
fi

if [[ "$file_type" != "txt" && "$file_type" != "csv" ]]; then
    echo "Invalid file type. Use 'txt' or 'csv'."
    exit 1
fi

# Ensure required commands are available
if ! command -v ping > /dev/null; then
    echo "Error: ping command is not available. Please install it."
    exit 1
fi

if [[ "$scan_ports" && ! $(command -v nmap) ]]; then
    echo "Installing nmap..."
    sudo apt-get install -y nmap || { echo "Failed to install nmap."; exit 1; }
fi

# Generate output directories and file name
output_dir="/ping_hub/ping_${base_ip}_${start_range}-${end_range}"
mkdir -p "$output_dir/ports"
output_file="$output_dir/ping_results.${file_type}"

# Warn if output file exists
if [[ -f "$output_file" ]]; then
    read -p "File $output_file exists. Overwrite? (y/n): " overwrite
    if [[ "$overwrite" != "y" ]]; then
        echo "Operation cancelled."
        exit 1
    fi
fi

# Function to resolve hostname
resolve_hostname_for_ip() {
    local ip="$1"
    local hostname_file="$output_dir/hostnames.${file_type}"
    echo "Resolving hostname for $ip..."
    hostname=$(nslookup "$ip" 2>/dev/null | awk -F': ' '/name =/ {print $2}')
    if [[ "$hostname" ]]; then
        if [[ "$file_type" == "csv" ]]; then
            echo "$ip,$hostname" >> "$hostname_file"
        else
            echo "$ip resolved to $hostname" >> "$hostname_file"
        fi
    else
        if [[ "$file_type" == "csv" ]]; then
            echo "$ip,unresolved" >> "$hostname_file"
        else
            echo "$ip could not be resolved" >> "$hostname_file"
        fi
    fi
}

# Function to resolve URL to IP
resolve_url_to_ip() {
    local url="$1"
    local resolved_file="$output_dir/resolved_urls.${file_type}"
    echo "Resolving URL $url to IP..."
    ip=$(nslookup "$url" 2>/dev/null | awk -F': ' '/Address: / {print $2}' | tail -n1)
    if [[ "$ip" ]]; then
        if [[ "$file_type" == "csv" ]]; then
            echo "$url,$ip" >> "$resolved_file"
        else
            echo "$url resolved to $ip" >> "$resolved_file"
        fi
    else
        if [[ "$file_type" == "csv" ]]; then
            echo "$url,unresolved" >> "$resolved_file"
        else
            echo "$url could not be resolved" >> "$resolved_file"
        fi
    fi
}

# Function to scan ports
scan_ports_for_ip() {
    local ip="$1"
    local port_file="$output_dir/ports/${ip}.${file_type}"

    if [[ "$scan_ports" == "important" ]]; then
        ports="22,80,443,1080,8000,3000"
    else
        ports="1-65535"
    fi

    echo "Scanning ports on $ip..."
    if [[ "$file_type" == "csv" ]]; then
        nmap -p "$ports" "$ip" -oG - | awk '/Up$/{print $2","$5}' > "$port_file"
    else
        nmap -p "$ports" "$ip" > "$port_file"
    fi
    echo "Port scan results saved to $port_file"
}

# Function to check SSL certificate expiration
check_ssl_expiration() {
    local ip="$1"
    local ssl_file="$output_dir/ssl_certificates.${file_type}"

    echo "Checking SSL certificate for $ip..."
    expiration=$(echo | openssl s_client -connect "$ip":443 -servername "$ip" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d'=' -f2)
    if [[ "$expiration" ]]; then
        if [[ "$file_type" == "csv" ]]; then
            echo "$ip,$expiration" >> "$ssl_file"
        else
            echo "$ip SSL certificate expires on $expiration" >> "$ssl_file"
        fi
    else
        if [[ "$file_type" == "csv" ]]; then
            echo "$ip,No SSL certificate detected" >> "$ssl_file"
        else
            echo "$ip has no SSL certificate detected" >> "$ssl_file"
        fi
    fi
}

# Function to ping IPs and save results
ping_ips() {
    > "$output_file"  # Clear the output file
    echo "Scanning IP range ${base_ip}.${start_range}-${base_ip}.${end_range}..."
    max_jobs=10  # Maximum parallel pings
    job_count=0
    for i in $(seq "$start_range" "$end_range"); do
        (
            ip="${base_ip}.${i}"
            if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
                echo "$ip,responded" >> "$output_file"
                if [[ "$scan_ports" ]]; then
                    scan_ports_for_ip "$ip"
                fi
                if [[ "$resolve_hostname" == true ]]; then
                    resolve_hostname_for_ip "$ip"
                fi
                if [[ "$check_ssl" == true ]]; then
                    check_ssl_expiration "$ip"
                fi
            else
                echo "$ip,unreachable" >> "$output_file"
            fi
        ) &
        ((job_count++))
        if [[ "$job_count" -ge "$max_jobs" ]]; then
            wait -n  # Wait for any
