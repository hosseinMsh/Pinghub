# ![PingHub](https://img.shields.io/badge/PingHub-🔍-blue)  
> A Powerful IP Scanning Tool  
> _Effortlessly monitor and scan your network_

![PingHub](https://github.com/hosseinMsh/Pinghub/blob/main/logo.png)

---

## 🛠️ Features

**PingHub** offers a variety of powerful features to help you manage your network effectively:

- **⚡ Ping IPs**: Check the availability of hosts within a specified IP range.
- **🌐 Exclude Patterns**: Easily exclude specific IP patterns from scans.
- **🔒 SSL Certificate Check**: Verify SSL certificate expiration for responding IPs.
- **📋 Output Formats**: Generate results in `.txt` or `.csv` formats.
- **🔙 Background Execution**: Run scans in the background for long durations.
- **📈 Parallel Scanning**: Scan multiple IPs simultaneously for faster results.

---

## 🚀 Installation

### Requirements

- Linux-based system (Ubuntu/Debian recommended)
- `ping` utility (should be pre-installed)

### Step-by-Step Installation

1. **Clone the repository**:

```bash
git clone https://github.com/hosseinMsh/PingHub.git
cd PingHub
```

2. **Make the script executable**:

```bash
chmod +x pinghub.sh
```

---

## 📄 Usage

You can run PingHub with various options to scan IP ranges, check SSL certificates, and more.

### Command Syntax

```bash
./pinghub.sh -s <start_ip> -e <end_ip> -f <file_type> [-r <exclude_pattern>] [--run-bg] [--check-ssl] [-v]
```

---

## 🏷️ Available Options

| Option | Description |
|--------|-------------|
| `-s, --start <start_ip>` | Starting IP address (e.g., `127.0.0.1`) |
| `-e, --end <end_ip>` | Ending IP address (e.g., `127.0.10.255`) |
| `-r, --exclude <exclude_pattern>` | IP pattern to exclude (e.g., `127.0.1.*`) |
| `-f, --file_type <csv/txt>` | Output file type (default: `txt`) |
| `--run-bg` | Run the script in the background |
| `--check-ssl` | Check SSL certificate expiration |
| `-v, --view` | View the status of all IPs |
| `-h, --help` | Show help message |

---

## ⚡ Example Commands

### Example 1: Ping Scan for IP Range

Ping a range of IPs from `192.168.1.1` to `192.168.1.10` and output the results in `.txt` format.

```bash
./pinghub.sh -s 192.168.1.1 -e 192.168.1.10 -f txt
```

### Example 2: Background Scan with Exclusion

Run a scan in the background, excluding a specific pattern.

```bash
./pinghub.sh -s 192.168.1.1 -e 192.168.1.10 -r 192.168.1.5 -f txt --run-bg
```

### Example 3: Check SSL Certificates

Check SSL certificates for devices responding on port 443 for IP range `192.168.1.1` to `192.168.1.10`.

```bash
./pinghub.sh -s 192.168.1.1 -e 192.168.1.10 --check-ssl -f csv
```

---

## 🤝 Contributing

We’d love to have your help improving **PingHub**! Here’s how you can contribute:

1. **Fork** the repository
2. Create a new branch (`git checkout -b feature-xyz`)
3. Make your changes
4. **Commit** your changes (`git commit -am 'Add new feature'`)
5. Push to the branch (`git push origin feature-xyz`)
6. Open a **Pull Request**

---

## 🛡️ License

PingHub is licensed under the [**MIT License**](LICENSE). Feel free to use, modify, and distribute it!

---

## 👏 Acknowledgements

- **PingHub** was inspired by the need for efficient network monitoring tools.
- Contributions and ideas from the open-source community are always welcome!
