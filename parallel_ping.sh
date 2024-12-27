#!/bin/bash

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

# Function to ping an IP
ping_ip() {
    local ip="$1"
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo "$ip is up"
    else
        echo "$ip is down"
    fi
}

# Main function to scan IPs
scan_ips() {
    for i in $(seq 0 255); do
        for j in $(seq 0 255); do
            for k in $(seq 0 255); do
                for l in $(seq 0 255); do
                    ip=$(int_to_ip $((i * 256 ** 3 + j * 256 ** 2 + k * 256 + l)))
                    echo "$ip"  # Output the IP to be processed
                done
            done
        done
    done | xargs -n 1 -P 100 bash -c 'ping_ip "$@"' _  # Run ping_ip in parallel
}

# Start scanning
scan_ips