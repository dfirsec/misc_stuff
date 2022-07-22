import sys
from pathlib import Path

try:
    from pdf2image import convert_from_path
    from pdf2image.exceptions import (PDFInfoNotInstalledError,
                                      PDFPageCountError, PDFSyntaxError)
except ImportError:
    sys.exit("pdf2image module required: pip install pdf2image")

r"""
   Poppler Installation
   Linux: sudo apt-get install poppler-utils -y

   Windows: Use choco or scoop: choco|scoop install poppler
   - or -
   Download: https://github.com/oschwartz10612/poppler-windows/releases/download/v21.03.0/Release-21.03.0.zip
   Add path to environment variables, i.e., C:\Utils\poppler-21.03.0\Library\bin
"""

if len(sys.argv) < 2:
    sys.exit("Usage: python pdf2img.py <PDF>")
else:
    pdf = sys.argv[1]

# Base directory paths
root = Path(__file__).resolve().parent
conv = root.joinpath("Converted_PDF")
imgs = conv.joinpath(Path(pdf).name.split(".pdf")[0].replace(" ", "_"))

if not imgs.exists():
    imgs.mkdir(parents=True)


try:
    with Path(imgs) as path:
        print("[+] Converting...")
        pages = convert_from_path(pdf, output_folder=Path(imgs), fmt="jpeg")
    print(f"[+] Done! Converted {len(pages)} pages")
except (PDFInfoNotInstalledError, PDFPageCountError, PDFSyntaxError) as e:
    print(e)
