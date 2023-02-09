"""Python Password Generator"""
import secrets
import string
import sys

try:
    from colorama import Fore, init
    init()  # initialize colorama
except ImportError:
    sys.exit("Please install colorama: pip install colorama --user")


def generator(strlen: str):
    """
    Takes a string length as an argument and returns a
    string of that length made up of random characters.

    :param strlen: The length of the string to be generated
    :return: A string of random characters.
    """
    strings = string.ascii_letters + string.digits + string.punctuation
    return "".join(secrets.choice(strings) for _ in range(int(strlen)))


if len(sys.argv) < 2:
    sys.exit(f"{Fore.RED}[ERROR]{Fore.RESET} Provide a password length")
else:
    try:
        if int(sys.argv[1]):
            if int(sys.argv[1]) > 50:
                sys.exit(f"{Fore.YELLOW}[WARNING]{Fore.RESET} Whew, that's too long!")  # nopep8
            print(f"Password: {Fore.CYAN}{generator(sys.argv[1])}{Fore.RESET}")
    except ValueError:
        sys.exit(f"{Fore.RED}[ERROR]{Fore.RESET} Must use an integer")
