import sys
from urllib.parse import urlparse

import requests
from dns import resolver, flags

CYN = "\033[36m"
RED = "\033[31m"
YEL = "\033[33m"
RST = "\033[0m"

if len(sys.argv) < 2:
    sys.exit(f"\n{CYN}Usage:{RST} python url_expander.py <URL>")
else:
    url = sys.argv[1]


def quad9(domain):
    # ref: https://www.quad9.net/support/faq/#testing
    dns_resp = None
    resolve = resolver.Resolver()
    resolve.nameservers = ["9.9.9.9", "149.112.112.112"]
    try:
        dns_resp = "non-malicious"
    except resolver.NXDOMAIN as error:
        for (_, resp) in error.responses().items():  # type: ignore
            recursion = resp.flags & flags.RA  # type: ignore
            dns_resp = "malicious" if recursion == 0 else "NXDOMAIN"
    except (resolver.NoAnswer, resolver.Timeout):
        pass
    except resolver.NoNameservers:
        dns_resp = f"{RED}[x]{RST} Failed to resolve domain {domain}"

    return dns_resp


def expand_url(short_url):
    session = requests.Session()
    session.max_redirects = 3
    timeout_value = 2.5
    try:
        response = session.head(short_url.strip(), timeout=timeout_value, allow_redirects=True)
    except requests.exceptions.ConnectionError:
        sys.exit(f"{RED}[x]{RST}{YEL} Connection Error:{RST} {short_url}")
    except requests.exceptions.MissingSchema as error:
        sys.exit(f"{RED}[x]{RST} {error}")
    else:
        return response


results = expand_url(url)
expanded = results.url.strip()
src_domain = urlparse(results.url.strip()).netloc

if results.history:
    print(f"{CYN}[+] {'History:':12}{RST}{' | '.join([results.url for results in results.history])}")

print(f"{CYN}[+] {'Expanded:':12}{RST}{expanded}")
print(f"{CYN}[+] {'Reputation:':12}{RST}{quad9(src_domain).title()}")
