#!/bin/bash

function show_usage() {
    echo "Usage: $0 [-s <start_ip> -e <end_ip>] [-r <exclude_pattern>] -f <file_type>"
    echo
    echo "Options:"
    echo "  -s, --start <start_ip>         Starting IP address (e.g., 127.0.0.1)"
    echo "  -e, --end <end_ip>             Ending IP address (e.g., 127.0.10.255)"
    echo "  -r, --exclude <exclude_pattern> IP pattern to exclude (e.g., 127.0.1.*)"
    echo "  -f, --file_type <csv/txt>      Output file type (default: txt)"
    echo "  --run-bg                        Run in the background"
    echo "  --scan-ports <important/all>    Scan important ports (e.g., 22, 80) or all ports"
    echo "  --resolve-hostname              Resolve hostnames for IP addresses"
    echo "  --resolve-url <url>             Resolve a URL or domain to its IP address"
    echo "  --check-ssl                     Check SSL certificate expiration for responding IPs"
    echo "  -v, --view                      View the status of all IPs"
    echo "  -h, --help                      Show this help message"
    echo "  --example                       Show example usage"
    exit 0
}

function show_examples() {
    echo "Examples of Usage:"
    echo
    echo "1. Ping a Range of IPs:"
    echo "   ./networkTools.sh -s 192.168.1.1 -e 192.168.1.10 -f txt"
    echo
    echo "2. Exclude a Pattern:"
    echo "   ./networkTools.sh -s 192.168.1.1 -e 192.168.1.10 -r 192.168.1.* -f txt"
    echo
    echo "3. Scan Important Ports:"
    echo "   ./networkTools.sh -s 192.168.1.1 -e 192.168.1.10 --scan-ports important"
    echo
    echo "4. Resolve Hostnames:"
    echo "   ./networkTools.sh -s 192.168.1.1 -e 192.168.1.10 --resolve-hostname"
    echo
    echo "5. Resolve a URL to IP:"
    echo "   ./networkTools.sh --resolve-url example.com"
    echo
    echo "6. Check SSL Certificates:"
    echo "   ./networkTools.sh -s 192.168.1.1 -e 192.168.1.10 --check-ssl"
    echo
    echo "7. View Status of All IPs:"
    echo "   ./networkTools.sh -v"
    echo
    echo "8. Run in Background:"
    echo "   ./networkTools.sh -s 192.168.1.1 -e 192.168.1.10 --run-bg"
    exit 0
}

# Check for no arguments
if [ $# -eq 0 ]; then
    show_usage
fi

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--start) start_ip="$2"; shift ;;
        -e|--end) end_ip="$2"; shift ;;
        -r|--exclude) exclude_pattern="$2"; shift ;;
        -f|--file_type) file_type="$2"; shift ;;
        --run-bg) run_bg=true ;;
        --scan-ports) scan_ports="$2"; shift ;;
        --resolve-hostname) resolve_hostname=true ;;
        --resolve-url) resolve_url="$2"; shift ;;
        --check-ssl) check_ssl=true ;;
        -v|--view) view_status=true ;;
        -h|--help) show_usage ;;
        --example) show_examples ;;
        *) echo "Unknown option: $1"; show_usage & show_examples ;;
    esac
    shift
done

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