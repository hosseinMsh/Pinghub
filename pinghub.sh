#!/bin/bash

# Configuration
DEFAULT_PORTS="20,21,22,23,25,53,67,68,80,110,143,161,194,443,465,587,993,995,3306,3389,5432,7993,8080,8443,9000,11211,27017,6379"
TIMEOUT=2
MAX_RETRIES=2
REPORT_FILE="network_scan_report_$(date +%Y%m%d_%H%M%S).txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize counters
TOTAL_IPS=0
REACHABLE_IPS=0
OPEN_PORTS=0
WARNINGS=0

# Setup output files
setup_output() {
    exec 3>&1 4>&2
    exec > >(tee -a "$OUTPUT_FILE") 2>&1
}

# Help message
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  -s IP            Start IP address for scanning range
  -e IP            End IP address for scanning range
  -r PATTERN       Exclude IPs matching pattern (e.g. 192.168.1.4*)
  -p PORTS         Comma-separated list of ports (default: $DEFAULT_PORTS)
  -d DOMAIN        Domain name to resolve
  --skip-ping      Skip ping check
  --no-ssl         Skip SSL check
  -o FILE          Output file for results
  --format FORMAT  Output format (e.g., json, csv)
  --ping-count N   Number of ping attempts (default: 1)
  --delay SECONDS  Delay between scans (default: 0)
  --check-deps     check deb pakage
  -h               Show this help message

Features:
  - IP range scanning with exclusions
  - Port scanning with custom/default ports
  - Hostname resolution
  - Domain to IP resolution
  - SSL certificate expiration check
  
Requirements:
	iputils-ping 
	nmap 
	netcat-openbsd 
	openssl 
	dnsutils
	jq
	whois

apt install iputils-ping nmap netcat-openbsd openssl dnsutils jq whois
EOF
}

# Check dependencies
check_deps() {
    local missing=()
    local dep_map=(
        "ping:iputils-ping:iputils"
        "nmap:nmap:nmap"
        "nc:netcat-openbsd:nmap-ncat"
        "openssl:openssl:openssl"
        "dig:dnsutils:bind-utils"
        "date:coreutils:coreutils"
    )

    # Check for missing commands
    for cmd in ping nmap nc openssl dig date; do
        if ! command -v $cmd &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "\n\033[1;31mMissing dependencies:\033[0m ${missing[*]}"
        echo -e "\n\033[1;33mInstallation instructions:\033[0m"

        for dep in "${missing[@]}"; do
            while IFS=":" read -r cmd deb_pkg rpm_pkg; do
                if [ "$cmd" == "$dep" ]; then
                    echo "Install $cmd using: sudo apt-get install $deb_pkg (Debian/Ubuntu) or sudo yum install $rpm_pkg (Red Hat/CentOS)"
                fi
            done <<< "$dep_map"
        done
        exit 1
    fi
}

# Validate IP address
validate_ip() {
    local ip=$1
    local stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Resolve domain to IP
resolve_domain() {
    local domain=$1
    local ip
    ip=$(dig +short "$domain" | tail -n 1)
    if [ -z "$ip" ]; then
        echo -e "${RED}Error: Could not resolve domain $domain${NC}"
        exit 1
    fi
    echo "Resolved $domain to $ip"
}

# Generate IP range
generate_ip_range() {
    local start_ip=$1
    local end_ip=$2
    local ip_list=()

    # Convert IPs to decimal
    local start_dec=$(printf '%d\n' 0x$(printf '%02x%02x%02x%02x\n' $(echo $start_ip | tr '.' ' ')))
    local end_dec=$(printf '%d\n' 0x$(printf '%02x%02x%02x%02x\n' $(echo $end_ip | tr '.' ' ')))

    for ((ip_dec=$start_dec; ip_dec<=$end_dec; ip_dec++)); do
        local ip=$(printf '%d.%d.%d.%d\n' $((ip_dec>>24&255)) $((ip_dec>>16&255)) $((ip_dec>>8&255)) $((ip_dec&255)))
        ip_list+=("$ip")
    done

    echo "${ip_list[@]}"
}

# Generate CIDR range
generate_cidr_range() {
    local cidr=$1
    nmap -sL -n "$cidr" | awk '/Nmap scan report for/{print $NF}'
}

# Show progress
show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    echo -ne "Progress: [$(printf "%-50s" "=" | tr ' ' '=')] $percent% ($current/$total)\r"
}

# Scan IP
scan_ip() {
    local ip=$1
    local ports=(${PORTS//,/ })

    for port in "${ports[@]}"; do
        if nc -z -w $TIMEOUT "$ip" "$port"; then
            echo -e "${GREEN}Port $port open on $ip${NC}"
            OPEN_PORTS+=1
        else
            echo -e "${RED}Port $port closed on $ip${NC}"
        fi
    done
}

# Main function
main() {
    local start_ip=""
    local end_ip=""
    local EXCLUDE_PATTERNS=""
    local PORTS="$DEFAULT_PORTS"
    local domain=""
    local OUTPUT_FILE=""
    local OUTPUT_FORMAT="txt"
    local PING_COUNT=1
    local SKIP_PING=false
    local SKIP_SSL=false
    local SCAN_DELAY=0

    while [[ $# -gt 0 ]]; do
        case $1 in
            -s) validate_ip "$2"; start_ip="$2"; shift 2 ;;
            -e) validate_ip "$2"; end_ip="$2"; shift 2 ;;
            -r) EXCLUDE_PATTERNS="$2"; shift 2 ;;
            -p) PORTS="$2"; shift 2 ;;
            -d) domain="$2"; shift 2 ;;
            -o) OUTPUT_FILE="$2"; shift 2 ;;
            --format) OUTPUT_FORMAT="$2"; shift 2 ;;
            --ping-count) PING_COUNT="$2"; shift 2 ;;
            --skip-ping) SKIP_PING=true; shift ;;
            --no-ssl) SKIP_SSL=true; shift ;;
            --delay) SCAN_DELAY="$2"; shift 2 ;;
			--check-deps) check_deps; exit 0 ;;
            -h) show_help; exit 0 ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    # Handle domain resolution
    if [ -n "$domain" ]; then
        resolve_domain "$domain"
        exit 0
    fi

    # Validate IP requirements
    if [ -z "$start_ip" ]; then
        echo -e "${RED}Error: Start IP/CIDR required${NC}"
        show_help
        exit 1
    fi

    # Generate IP list
    if [[ "$start_ip" == */* ]]; then
        IP_LIST=$(generate_cidr_range "$start_ip")
    else
        if [ -z "$end_ip" ]; then
            IP_LIST="$start_ip"
        else
            IP_LIST=$(generate_ip_range "$start_ip" "$end_ip")
        fi
    fi

    TOTAL_IPS=$(echo "$IP_LIST" | wc -l)
    CURRENT_IP=0

    echo "$IP_LIST" | while read -r ip; do
        show_progress $((++CURRENT_IP)) $TOTAL_IPS
        if [ -n "$EXCLUDE_PATTERNS" ] && [[ "$ip" == $EXCLUDE_PATTERNS ]]; then
            continue
        fi

        if [ "$SKIP_PING" = true ] || ping -c "$PING_COUNT" -W 1 "$ip" &>/dev/null; then
            scan_ip "$ip"
            REACHABLE_IPS+=1
        fi
        sleep $SCAN_DELAY
    done

    echo -e "\n${YELLOW}=== Scan Summary ===${NC}"
    echo -e "Total IPs scanned: $TOTAL_IPS"
    echo -e "Reachable hosts: $REACHABLE_IPS"
    echo -e "Total open ports: $OPEN_PORTS"
    echo -e "SSL warnings: $WARNINGS"
    echo -e "Scan duration: $SECONDS seconds"
}

# Check dependencies
check_deps

# Run the main function with all arguments
main "$@"
