"""Expand short URLs and check reputation of source domain."""

import sys
from urllib.parse import urlparse

import requests
from dns import resolver, flags

cyan = "\033[36m"
red = "\033[31m"
yellow = "\033[33m"
reset = "\033[0m"

if len(sys.argv) < 2:
    sys.exit(f"\n{cyan}Usage:{reset} python url_expander.py <URL>")
else:
    url = sys.argv[1]


def quad9(domain: str) -> str | None:
    """Return reputation of domain from Quad9 DNS server."""
    # ref: https://www.quad9.net/support/faq/#testing
    dns_resp = None
    resolve = resolver.Resolver()
    resolve.nameservers = ["9.9.9.9", "149.112.112.112"]
    try:
        dns_resp = "non-malicious"
    except resolver.NXDOMAIN as error:
        for _, resp in error.responses().items():  # type: ignore
            recursion = resp.flags & flags.RA  # type: ignore
            dns_resp = "malicious" if recursion == 0 else "NXDOMAIN"
    except (resolver.NoAnswer, resolver.Timeout):
        pass
    except resolver.NoNameservers:
        dns_resp = f"{red}[x]{reset} Failed to resolve domain {domain}"

    return dns_resp


def expand_url(short_url: str) -> requests.Response:
    """Return expanded URL from short URL."""
    session = requests.Session()
    session.max_redirects = 3
    timeout_value = 2.5
    try:
        response = session.head(short_url.strip(), timeout=timeout_value, allow_redirects=True)
    except requests.exceptions.ConnectionError:
        sys.exit(f"{red}[x]{reset}{yellow} Connection Error:{reset} {short_url}")
    except requests.exceptions.MissingSchema as error:
        sys.exit(f"{red}[x]{reset} {error}")
    else:
        return response


results = expand_url(url)
expanded = results.url.strip()
src_domain = urlparse(results.url.strip()).netloc
quad9_result = quad9(src_domain)

if results.history:
    print(f"{cyan}[+] {'History:':12}{reset}{' | '.join([results.url for results in results.history])}")

print(f"{cyan}[+] {'Expanded:':12}{reset}{expanded}")
if quad9_result is not None:
    print(f"{cyan}[+] {'Reputation:':12}{reset}{quad9_result.title()}")
