import argparse
import os
import zipfile
from typing import Callable


def is_zip_file(file_path: str):
    """
    If the first four bytes of the file are the ASCII characters "PK" followed by the two bytes
    "\x03\x04", then the file is a zip file.

    :param file_path: The path to the file you want to check
    :type file_path: str
    :return: The return value is a boolean.
    """
    with open(file_path, "rb") as f:
        header = f.read(4)
        return header == b"\x50\x4B\x03\x04"


def extract_file_contents(file_path: str):
    """
    If the file is a zip file and contains a file named "[Content_Types].xml", then return "MS Office file",
    otherwise return "Zip file".

    :param file_path: The path to the file you want to extract the contents of
    :type file_path: str
    :return: A string
    """
    if not is_zip_file(file_path):
        return None

    with zipfile.ZipFile(file_path) as zf:
        files = zf.namelist()
        return "MS Office file" if "[Content_Types].xml" in files else "Zip file"


def decorator(func: Callable):
    """
    Returns a wrapper function.

    :param func: The function to be decorated
    :return: The wrapper function.
    """

    def wrapper(*args, **kwargs):
        print("\n")
        func(*args, **kwargs)
        print("=" * 25)

    return wrapper


@decorator
def func(name: str, files: str):
    """
    Takes a string and a list of strings as arguments and prints the length of the list of
    strings.

    :param name: The name of the directory
    :type name: str
    :param files: The list of files to be processed
    :type files: str
    """
    print(f"{name}: {len(files)} files")


def determine_file_type(file_path: str):
    """
    Returns the file type of the file whose data is passed in as an argument

    :param data: The data to be checked
    :return: The file type of the file.

    https://en.wikipedia.org/wiki/List_of_file_signatures
    https://www.garykessler.net/library/file_sigs.html
    """

    # Dictionary to store file signatures and corresponding file types
    file_signatures = {
        # Office files
        "MS Word": b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1",
        "MS Word (2007+)": b"\x50\x4b\x03\x04\x14\x00\x06\x00",
        "MS Excel": b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1",
        "MS Excel (2007+)": b"\x50\x4b\x03\x04\x14\x00\x06\x00",
        "MS Powerpoint": b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1",
        "MS Powerpoint (2007+)": b"\x50\x4b\x03\x04\x14\x00\x06\x00",
        # Audio files
        "AAC": b"\xff\xf1",
        "FLAC": b"\x66\x4c\x61\x43",
        "MP3": b"\x49\x44\x33",
        "WAV": b"\x52\x49\x46\x46",
        # Video files
        "AVI": b"\x52\x49\x46\x46",
        "FLV": b"\x46\x4c\x56\x01",
        "MKV": b"\x1a\x45\xdf\xa3",
        "MOV": b"\x6d\x6f\x6f\x76",
        "MP4": b"\x00\x00\x00\x20\x66\x74\x79\x70",
        "MPG": b"\x00\x00\x01\xba",
        "WEBM": b"\x1a\x45\xdf\xa3",
        # Image files
        "BMP": b"\x42\x4d",
        "GIF": b"\x47\x49\x46\x38",
        "IMG": b"\x53\x43\x4d\x49",
        "JPEG": b"\xff\xd8\xff",
        "JPG": b"\xff\xd8\xff",
        "PNG": b"\x89\x50\x4e\x47",
        "RIFF": b"\x52\x49\x46\x46",
        "WEBP": b"\x57\x45\x42\x50",
        # Text files
        "RTF": b"\x7b\x5c\x72\x74\x66\x31",
        # Compressed files
        "7Z": b"\x37\x7a\xbc\xaf\x27\x1c",
        "GZ": b"\x1f\x8b\x08",
        "RAR": b"\x52\x61\x72\x21\x1a\x07\x00",
        "TAR": b"\x75\x73\x74\x61\x72\x00\x30\x30",
        "ZIP": b"\x50\x4b\x03\x04",
        # Database files
        "MDB": b"\x53\x74\x61\x6e\x64\x61\x72\x64\x20\x4a\x65\x74\x20\x44\x42",
        "ACCDB": b"\x00\x01\x00\x53\x74\x61\x6e\x64\x61\x72\x64\x20\x41\x43\x45\x20\x44\x42",
        "SQLite": b"\x53\x51\x4C\x69\x74\x65\x20\x66\x6F\x72\x6D\x61\x74\x20\x33\x00",
        # Executable files
        "EXE": b"\x4d\x5a",
        "MSI": b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1",
        "DMG": b"\x78\x01\x73\x0d\x62\x62\x60",
        # Script files
        "PY": b"\x23\x21\x2f\x75\x73\x72\x2f\x62",
        "JS": b"\x2f\x2a\x0a\x20\x20\x20\x20\x20",
        "PHP": b"\x3c\x3f\x70\x68\x70",
        "RB": b"\x23\x21\x2f\x75\x73\x72\x2f\x62",
        # CAD files
        "DWG": b"\x41\x43\x31\x30",
        "DXF": b"\x53\x49\x4f\x4e\x20\x44\x45\x56\x45\x4c\x20\x56\x65\x72\x73\x69\x6f\x6e",
        # Document files
        "EPUB": b"\x50\x4b\x03\x04\x0a\x00\x02\x00",
        "PDF": b"\x25\x50\x44\x46",
    }

    try:
        with open(file_path, "rb") as f:
            file_bytes = f.read(20)  # Read the first 20 bytes of the file
            return next(
                (
                    file_type
                    for file_type, file_signature in file_signatures.items()
                    if file_bytes.startswith(file_signature)
                ),
                None,
            )
    except (FileNotFoundError, PermissionError):
        return None


def scantree(directory: str):
    """
    Recursively scans a directory and returns a generator of all the files in that directory

    :param directory: str = The directory to scan
    :type directory: str
    """
    with os.scandir(directory) as entries:
        for entry in entries:
            try:
                if not entry.name.startswith(".") and entry.is_dir(follow_symlinks=False):
                    yield from scantree(entry.path)
                else:
                    yield entry.path
            except PermissionError:
                continue


def scan_directory_for_file_types(directory: str):
    """
    Scans a directory for files, and returns a dictionary of file types and the files that match that
    file type.

    :param directory: The directory to scan
    :type directory: str
    :return: A dictionary of file types and a list of file paths.
    """
    file_types = {}
    for file_path in scantree(directory):
        if file_type := determine_file_type(str(file_path)):
            if file_type not in file_types:
                file_types[file_type] = []
            file_types[file_type].append(file_path)
    return file_types


def parser():
    """
    Takes a directory path as an argument and returns a list of tuples containing the file
    name and the file size.
    :return: The parse object is being returned.
    """
    parse = argparse.ArgumentParser(description="Determine file types in a directory")
    parse.add_argument("PATH", help="Directory path to scan")
    return parse


def main():
    """
    Takes a path, scans the directory for file types, and then prints the file types and the files
    that are associated with them.
    """
    args = parser().parse_args()
    file_types = scan_directory_for_file_types(args.PATH)
    ext = ".docx", ".xlsx", ".pptx"
    for file_type, files in file_types.items():
        func(file_type, files)
        for file in files:
            if file.endswith(ext):
                print(f"  - {file} (\u001b[32m{extract_file_contents(file)}\u001b[0m)")
            else:
                print(f"  - {file}")


if __name__ == "__main__":
    main()
