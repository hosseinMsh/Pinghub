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
    echo "  --run-bg                        Run in the background"
    echo "  --scan-ports <important/all>    Scan important ports (e.g., 22, 80) or all ports"
    echo "  --resolve-hostname              Resolve hostnames for IP addresses"
    echo "  --resolve-url <url>             Resolve a URL or domain to its IP address"
    echo "  --check-ssl                     Check SSL certificate expiration for responding IPs"
    echo "  -v, --view                      View the status of all IPs"
    echo "  -h, --help                      Show this help message"
    echo "  --ping                          Ping a range of IPs"
    echo "  --example                       Show example usage"
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
        --run-bg) run_bg=true ;;
        --scan-ports) scan_ports="$2"; shift ;;
        --resolve-hostname) resolve_hostname=true ;;
        --resolve-url) resolve_url="$2"; shift ;;
        --check-ssl) check_ssl=true ;;
        -v|--view) view_status=true ;;
        -h|--help) show_help ;;
        --example) show_examples ;;
        --ping) ping=true ;;
        *) echo "Unknown option: $1"; show_help ;;
    esac
    shift
done

# Validate input
if [ "$ping" = true ]; then
    if [[ -z "$start_ip" || -z "$end_ip" || -z "$file_name" ]]; then
        echo "Error: You must provide a start IP, end IP, and file name for pinging."
        exit 1
    fi
    echo "Pinging IP range from $start_ip to $end_ip..."
    ./pinghub.sh -s "$start_ip" -e "$end_ip" -r "$exclude_pattern" -f "$file_name"
    exit 0
fi

# Add other functionalities as needed
echo "Network tools operations completed."

# Call sub-scripts based on options
if [ "$view_status" = true ]; then
    echo "Viewing status of all IPs..."
    # Call your view function or script here
    ./pinghub.sh --view
fi

if [ -n "$start_ip" ] && [ -n "$end_ip" ]; then
    echo "Pinging IP range from $start_ip to $end_ip..."
    ./pinghub.sh -s "$start_ip" -e "$end_ip" -f "${file_type:-txt}" -r "$exclude_pattern"
fi

if [ -n "$scan_ports" ]; then
    echo "Scanning ports..."
    ./porthub.sh --scan-ports "$scan_ports" -s "$start_ip" -e "$end_ip"
fi

if [ "$resolve_hostname" = true ]; then
    echo "Resolving hostnames..."
    ./pinghub.sh --resolve-hostname -s "$start_ip" -e "$end_ip"
fi

if [ -n "$resolve_url" ]; then
    echo "Resolving URL: $resolve_url..."
    ./urlToIp.sh "$resolve_url"
fi

if [ "$check_ssl" = true ]; then
    echo "Checking SSL certificates..."
    ./ipToUrl.sh --check-ssl -s "$start_ip" -e "$end_ip"
fi

# Add any additional functionality as needed

echo "Network tools operations completed."