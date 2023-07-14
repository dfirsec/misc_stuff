# Miscellaneous Scripts

Repo for miscellaneous scripts that may, or may not work for you. :smirk:

## Python 
| Script Name         | Use Function                                     |
| ------------------- | :----------------------------------------------- |
| `ff_hist_viewer.py` | firefox history viewer                           |
| `file_offsets.py`   | determine file types                             |
| `file_size.py`      | determine file sizes                             |
| `ioc_extractor.py`  | extract IOCs from csv, txt, and xml files        |
| `pass_gen.py`       | password generator                               |
| `pdf2img.py`        | convert pdf file to image files                  |
| `social_check.py`   | check for username accross multiple social sites |
| `rev_dns_qry.py`    | reverse query for PTR records                    |
| `url_expander.py`   | expand shortened URLs                            |

```python
"""Takes a screenshot"""
from datetime import datetime

from PIL import ImageGrab

DTSTR = datetime.now().strftime("%Y%m%d-%H%M%S")
IMG = f"screenshot_{DTSTR}.png"

SCREENSHOT = ImageGrab.grab(bbox=None)
SCREENSHOT.save(IMG, "PNG")
SCREENSHOT.show()
```

## Bash/Batch
| Script Name              | Use Function                                     |
| ------------------------ | :----------------------------------------------- |
| `maintenance_script.sh ` | generic linux cleanup script                     |
| `mac_cleaner`            | cleanup script I used on my own Mac              |
| `update_repo`            | remove old commits from github repo              |
| `wget-fetch.sh`          | use wget to fetch a complete webpage             |

## JS/Misc
| Script Name         | Use Function                                     |
| ------------------- | :----------------------------------------------- |
| `ffprofile`         | firefox profile/preferences                      |


