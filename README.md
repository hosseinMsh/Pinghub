
# PingWatch

PingWatch is a powerful and flexible network scanning tool that allows you to monitor IP ranges, resolve hostnames, check SSL certificate expirations, and scan ports for a variety of hosts. Whether you're managing a local network or a large-scale infrastructure, PingWatch provides essential utilities to monitor and audit your devices efficiently.

---

## 🚀 Features

- **Ping hosts**: Quickly check the availability of hosts in a specified range.
- **Resolve hostnames**: Automatically resolve IP addresses to hostnames.
- **Port scanning**: Scan essential ports (e.g., 22, 80, 443) or all ports on hosts.
- **SSL certificate check**: Verify SSL certificate expiration for devices that respond on port 443.
- **Background execution**: Run the tool in the background for long-range scans.
- **Output formats**: Generate results in `.txt` or `.csv` formats.

---

## 🛠 Installation

### Requirements

- **Linux-based system** (tested on Ubuntu/Debian)
- **Ping** utility (should be installed by default)
- **nmap** for port scanning (can be installed automatically)
- **OpenSSL** for SSL checks (usually pre-installed)

### Step 1: Clone the repository

```bash
git clone https://github.com/hosseinMsh/PingWatch.git
cd PingWatch
```

### Step 2: Install dependencies

If `nmap` is not installed on your system, PingWatch will attempt to install it automatically. However, you can also install it manually if needed:

```bash
sudo apt-get update
sudo apt-get install -y nmap
```

### Step 3: Make the script executable

```bash
chmod +x pingwatch.sh
```

---

## 📄 Usage

PingWatch is designed to be simple yet powerful. Below are the usage details and examples.

### Command Syntax

```bash
./pingwatch.sh -b <base_ip> -s <start_range> -e <end_range> -f <file_type> [--run-bg] [--scan-ports important/all] [--resolve-hostname] [--resolve-url <url>] [--check-ssl] [-v]
```

### Options:

- `-b, --base_ip <base_ip>`: Base IP address (e.g., `192.168.1`)
- `-s, --start <start_range>`: Start of the IP range (1-255)
- `-e, --end <end_range>`: End of the IP range (1-255)
- `-f, --file_type <csv/txt>`: Output file type (default: `txt`)
- `--run-bg`: Run the script in the background
- `--scan-ports <important/all>`: Scan important ports (e.g., 22, 80) or all ports (`all`)
- `--resolve-hostname`: Resolve hostnames for IP addresses
- `--resolve-url <url>`: Resolve a URL to its IP address
- `--check-ssl`: Check SSL certificate expiration
- `-v, --view`: View the status of all IPs
- `-h, --help`: Show help message

---

## ⚡ Examples

### Example 1: Simple Ping Scan

Scan a range of IPs and output results in `.txt` format.

```bash
./pingwatch.sh -b 192.168.1 -s 1 -e 10 -f txt
```

### Example 2: Scan Ports for IP Range

Scan ports 22, 80, 443, etc., for IP range `192.168.1.1` to `192.168.1.10`.

```bash
./pingwatch.sh -b 192.168.1 -s 1 -e 10 --scan-ports important -f csv
```

### Example 3: Background Scan with Hostname Resolution

Run the scan in the background and resolve hostnames for the IP range `192.168.1.1` to `192.168.1.10`.

```bash
./pingwatch.sh -b 192.168.1 -s 1 -e 10 --run-bg --resolve-hostname -f txt
```

### Example 4: Check SSL Certificates

Scan IP range `192.168.1.1` to `192.168.1.10` and check SSL certificates for devices responding on port 443.

```bash
./pingwatch.sh -b 192.168.1 -s 1 -e 10 --check-ssl -f csv
```

### Example 5: Resolve a URL to IP

Resolve a URL (`example.com`) to its IP address.

```bash
./pingwatch.sh --resolve-url example.com -f txt
```

---

## 🔄 Background Execution

Use the `--run-bg` flag to execute the scan in the background. This is especially useful for long-range scans or monitoring over extended periods.

Example:

```bash
./pingwatch.sh -b 192.168.1 -s 1 -e 254 --run-bg
```

---

## 📝 Output

PingWatch generates results in either `.txt` or `.csv` formats. Results include:

- **Ping responses** (whether an IP is up or unreachable)
- **Port scan results** (open ports for each IP)
- **Hostname resolutions** (if a hostname is found for each IP)
- **SSL expiration dates** (if SSL is detected for the IP)

---

## 🤝 Contribution

We welcome contributions to PingWatch! If you'd like to contribute:

1. Fork this repository.
2. Create a new branch (`git checkout -b feature-xyz`).
3. Make your changes.
4. Commit and push your changes (`git commit -am 'Add new feature'`).
5. Create a pull request.

---

## 📄 License

This project is licensed under the MIT License.
