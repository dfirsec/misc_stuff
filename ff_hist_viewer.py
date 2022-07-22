import argparse
import sqlite3
import sys

try:
    from colorama import Fore, Style, init
    init()  # Initialize colorama
except ImportError:
    sys.exit("\nPlease install colorama: pip install colorama --user\n")

""" Windows Location """
# C:\Users\<username>\AppData\Roaming\Mozilla\Firefox\Profiles\xxxxxxxx.default\places.sqlite

""" Linux Location """
# /home/<username>/.mozilla/firefox/xxxxxxxx.default/places.sqlite

""" Mac Location """
# Users/<username>/Library/Application Support/Firefox/Profiles/xxxxxxxx.default


class Termcolors:
    # Unicode Symbols and colors
    CYAN = Fore.CYAN
    YELLOW = Fore.YELLOW
    RESET = Fore.RESET
    ARROW = f"{CYAN}\u279C {RESET}"
    WARNING = f"{YELLOW}\u03DF {RESET}"


def history(db):
    tc = Termcolors()
    try:
        conn = sqlite3.connect(db)
        cursor = conn.cursor()
        bookmarks = "SELECT url, moz_places.title, datetime(last_visit_date/1000000, \"unixepoch\") FROM moz_places JOIN moz_bookmarks ON moz_bookmarks.fk=moz_places.id WHERE visit_count >= 0 AND moz_places.url LIKE 'http%' order by dateAdded desc;"
        history = "SELECT url, datetime(visit_date/1000000, \"unixepoch\") FROM moz_places, moz_historyvisits WHERE visit_count >= 0 AND moz_places.id==moz_historyvisits.place_id;"

        print(f"{tc.YELLOW}\n --[ Bookmarks ]--{tc.RESET}")
        for row in cursor.execute(bookmarks):
            url = str(row[0])
            bookmark = str(row[1])
            last_visited = str(row[2])
            if row[0] and row[2] != None:
                print(f"{tc.ARROW} {last_visited}: {bookmark}, {url}")
            else:
                print(f"{tc.ARROW} {url}")

        print(f"{tc.YELLOW}\n --[ History ]--{tc.RESET}")
        for row in cursor.execute(history):
            url = str(row[0])
            date = str(row[1])
            print(f"{tc.ARROW} {date}: {url}")

    except Exception as err:
        sys.exit(f"{tc.WARNING} Error reading database. {err}")


def main():
    parser = argparse.ArgumentParser("Firefox History & Bookmarks Viewer")
    parser.add_argument("file", help="Firefox sqlite file path")
    args = parser.parse_args()
    places = args.file

    if places:
        history(places)
    else:
        sys.exit("Missing path to SQLite database.")


if __name__ == "__main__":
    main()
