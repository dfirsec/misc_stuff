"""Find api_key references in files."""

import multiprocessing
import re
import sys
from functools import partial
from pathlib import Path


def check_file(file_path: Path, api_key_regexes: dict) -> Path | None:
    """Check if a file contains 'api_key'."""
    file_ext = file_path.suffix
    if file_ext in api_key_regexes and api_key_regexes[file_ext].search(file_path.read_text(encoding="utf-8")):
        return file_path
    return None


def find_api_key_references(root_dir: str) -> list:
    """Find api_key references in files."""
    patterns = {
        ".bashrc": re.compile(r"export\s+API_KEY\s*=\s*.+", re.IGNORECASE),
        ".cfg": re.compile(r"api_key\s*=\s*.+", re.IGNORECASE),
        ".conf": re.compile(r"api_key\s*=\s*.+", re.IGNORECASE),
        ".config": re.compile(r"\bapi_key\s*=\s*\w+", re.IGNORECASE),
        ".dockerfile": re.compile(r"ENV\s+API_KEY\s*=\s*.+", re.IGNORECASE),
        ".ini": re.compile(r"api_key\s*=\s*.+", re.IGNORECASE),
        ".json": re.compile(r"\"api_key\"\s*:\s*\".+\"", re.IGNORECASE),
        ".php": re.compile(r"\$api_key\s*=\s*\'\w+\'", re.IGNORECASE),
        ".properties": re.compile(r"api_key\s*=\s*.+", re.IGNORECASE),
        ".py": re.compile(r'\bapi_key\s*=\s*["\']\w+["\']', re.IGNORECASE),
        ".toml": re.compile(r"api_key\s*=\s*.+", re.IGNORECASE),
        ".xml": re.compile(r"<api_key>\s*.*\s*</api_key>", re.IGNORECASE),
        ".yaml": re.compile(r"\bapi_key\s*:\s*\w+", re.IGNORECASE),
        ".yml": re.compile(r"\bapi_key\s*:\s*\w+", re.IGNORECASE),
    }
    files_with_api_key = []

    with multiprocessing.Pool() as pool:
        files = list(Path(root_dir).rglob("*"))
        files_with_api_key = pool.map(partial(check_file, api_key_regexes=patterns), files)

    return [file for file in files_with_api_key if file]


def main() -> None:
    """Main function."""
    root_dir = input("Enter the root directory to search for 'api_key': ")
    try:
        files_with_api_key = find_api_key_references(root_dir)
        if files_with_api_key:
            print("\nFiles containing 'api_key':")
            print("\n".join(map(str, files_with_api_key)))
        else:
            print("No files found containing 'api_key'.")
    except KeyboardInterrupt:
        print("\nExecution interrupted by user!")
        sys.exit(0)


if __name__ == "__main__":
    main()
