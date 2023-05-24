"""Firefox History & Bookmarks Viewer."""

import argparse
import sqlite3
import sys

""" Windows Location """
# C:\Users\<username>\AppData\Roaming\Mozilla\Firefox\Profiles\xxxxxxxx.default\places.sqlite

""" Linux Location """
# /home/<username>/.mozilla/firefox/xxxxxxxx.default/places.sqlite

""" Mac Location """
# Users/<username>/Library/Application Support/Firefox/Profiles/xxxxxxxx.default


class Termcolors:
    """Terminal Colors."""

    # Unicode Symbols and colors
    cyan = "\033[96m"
    yellow = "\033[93m"
    reset = "\033[0m"
    arrow = f"{cyan}\u279C {reset}"
    warning = f"{yellow}\u03DF {reset}"


def history(db: str) -> None:
    """Print Firefox history and bookmarks."""
    tc = Termcolors()
    try:
        conn = sqlite3.connect(db)
        cursor = conn.cursor()
        bookmarks = "SELECT url, moz_places.title, datetime(last_visit_date/1000000, \"unixepoch\") FROM moz_places JOIN moz_bookmarks ON moz_bookmarks.fk=moz_places.id WHERE visit_count >= 0 AND moz_places.url LIKE 'http%' order by dateAdded desc;"
        history = 'SELECT url, datetime(visit_date/1000000, "unixepoch") FROM moz_places, moz_historyvisits WHERE visit_count >= 0 AND moz_places.id==moz_historyvisits.place_id;'

        print(f"{tc.yellow}\n[ Bookmarks ]{tc.reset}")
        for row in cursor.execute(bookmarks):
            url = str(row[0])
            if row[0] and row[2] is not None:
                bookmark = str(row[1])
                last_visited = str(row[2])
                print(f"{tc.arrow} {last_visited}: {bookmark}, {url}")
            else:
                print(f"{tc.arrow} {url}")

        print(f"{tc.yellow}\n[ History ]{tc.reset}")
        for row in cursor.execute(history):
            url = str(row[0])
            date = str(row[1])
            print(f"{tc.arrow} {date}: {url}")

    except Exception as err:
        sys.exit(f"{tc.warning} Error reading database. {err}")


def main() -> None:
    """Main function."""
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
