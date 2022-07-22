"""Reverse query for PTR records"""

import sys
from ipaddress import AddressValueError, IPv4Address

try:
    import dns.resolver
except ImportError:
    sys.exit("Please install dnspython (pip install dnspython --user)")


def resolve(ip_addr):
    try:
        resolver = dns.resolver.resolve_address(ip_addr)
        resolver.timeout = 1.0
        resolver.lifetime = 1.0
        resolver.nameservers = ["8.8.8.8", "9.9.9.9", "208.67.222.222"]
    except dns.resolver.NXDOMAIN:
        print(f"[-] Domain does not exist for {ip_addr}")
    except dns.resolver.NoAnswer:
        print(f"[-] No Resource Records available for {ip_addr}")
    except dns.resolver.NoNameservers:
        print(f"[-] No nameservers are available to answer for {ip_addr}")
    except dns.exception.Timeout:
        print("[-] Timeout")
    else:
        for results in resolver:
            print(f"[+] {ip_addr} -> {results.to_text().rstrip('.')}")


try:
    IP = IPv4Address(sys.argv[1])
except AddressValueError:
    sys.exit("Please enter a valid IP address.")
except IndexError:
    sys.exit("Please enter an IP address.")
else:
    resolve(IP)
