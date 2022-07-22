import secrets
import string
import sys

__description__ = "Python Password Generator"

try:
    from colorama import Fore, init
    init()  # initialize colorama
except ImportError:
    sys.exit("Please install colorama: pip install colorama --user")


def str_gen(str_len):
    s = string.ascii_letters + string.digits + string.punctuation
    return ''.join(secrets.choice(s) for _ in range(int(str_len)))


if len(sys.argv) < 2:
    sys.exit(f"{Fore.RED}[ERROR]{Fore.RESET} Provide a password length")
else:
    try:
        if int(sys.argv[1]):
            if int(sys.argv[1]) > 50:
                sys.exit(f"{Fore.YELLOW}[WARNING]{Fore.RESET} Whew, that's too long!")  # nopep8
            print(f"Password: {Fore.CYAN}{str_gen(sys.argv[1])}{Fore.RESET}")
    except ValueError:
        sys.exit(f"{Fore.RED}[ERROR]{Fore.RESET} Must use an integer")
