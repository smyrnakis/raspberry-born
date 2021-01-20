# Nmap (Network mapper)

*Article: https://www.tecmint.com/nmap-command-examples/*

<br>

This guide is about installing and using the [Nmap](https://nmap.org) tool.

## Installation
``` bash
sudo apt-get install nmap -y
```

## Usage

> For the examples bellow, I will use the hostname "scanme.nmap.org". You could use either names or IP addresses (like the local 192.168.1.50).
>
> Be sure to scan **only** domains that you are allowed to!

### Simple & fast scan

``` bash
# simple scan
sudo nmap scanme.nmap.org

# fast scan: checks the 100 most common ports
sudo nmap -F scanme.nmap.org
```

### Port specific
``` bash
# scan ports 80 & 443
sudo nmap -p 80,443 scanme.nmap.org

# scan ports 500 to 1500
sudo nmap -p 500-1500 scanme.nmap.org

# scan all ports (1-65535)
sudo nmap -p- scanme.nmap.org
```

### Scan types
``` bash
# TCP
sudo nmap -sT scanme.nmap.org

# UDP
sudo nmap -sU scanme.nmap.org

# SYN scan (not stealthy)
sudo nmap -sS scanme.nmap.org

# invalid TCP headers (stealthy-er than SYN scan)
sudo nmap -sN scanme.nmap.org
```

### Extra options
``` bash
# resolve service version
sudo nmap -sV 192.168.1.1

# detect Operating System & version
sudo nmap -A scanme.nmap.org

# port details, MAC, Operating System
sudo nmap -O 192.168.1.1

# don't wait for PING reply
sudo nmap -Pn -F scanme.nmap.org

# list devices on a local network 192.168.1.0/24
sudo nmap -sn 192.168.1.0/24
```

## Extra

### Common ports
``` bash
20      # FTP data
21      # FTP control port
22      # SSH
23      # Telnet
25      # SMTP
43      # WHOIS protocol
53      # DNS services
67      # DHCP server port
68      # DHCP client port
80      # HTTP
110     # POP3 mail port
113     # Ident authentication services on IRC networks
143     # IMAP mail port
161     # SNMP
194     # IRC
389     # LDAP port
443     # HTTPS
587     # SMTP
631     # CUPS printing daemon port
666     # DOOM - This legacy game actually has its own special port
```