#!/bin/bash
#todo --resolve-url ,--check-ssl ,--resolve-hostname  ,--scan-ports <important/all>
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

# Function to show examples
show_examples() {
    echo "Examples of Usage:"
    echo
    echo "1. Ping a Range of IPs:"
    echo "   ./networkTools.sh --ping -s 192.168.1.1 -e 192.168.1.10 -f my_output"
    echo "   This will ping all IPs from 192.168.1.1 to 192.168.1.10 and save the results to my_output.csv."
    echo
    echo "2. Exclude a Pattern:"
    echo "   ./networkTools.sh --ping -s 192.168.1.1 -e 192.168.1.10 -r 192.168.1.5 -f my_output"
    echo "   This will ping the range but skip 192.168.1.5."
    echo
    echo "3. View Help:"
    echo "   ./networkTools.sh -h"
    echo "   This will display the help message."
    echo
    echo "4. View Status of All IPs:"
    echo "   ./networkTools.sh -v"
    echo "   This will show the status of all IPs."
    echo
    echo "5. Run in Background:"
    echo "   ./networkTools.sh --ping -s 192.168.1.1 -e 192.168.1.10 --run-bg"
    echo "   This will run the ping operation in the background."
    exit 0
}

# Default values
start_ip=""
end_ip=""
exclude_pattern="127.0.0.256"
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
    echo "Pinging IP range from $start_ip to $end_ip"
    bash pinghub.sh -s "$start_ip" -e "$end_ip" -r "$exclude_pattern" -f "$file_name"
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
     if [[ -f "$file_name" ]]; then
        bash ipToUrl.sh "$file_name"
    else
        echo "Error: File '$file_name' does not exist."
        exit 1
    fi
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

# shellcheck disable=SC1073
echo "Network tools operations completed. "