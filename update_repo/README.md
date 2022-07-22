
# Update Github Repo

Script removes old commits from your github repo.

## Installation

\*nix systems require zip and unzip installed.

```sudo apt install zip unzip```

Windows systems requires [7zip](https://www.7-zip.org/) installed.

### Step 1

Clone your repository

```git clone https://github.com/<USER>/<REPO>.git```

### Step 2

#### \*nix 

Copy the script ```update_repo.sh``` to your repository source directory and make it executable.

```text
cd <your repository directory>
chmod +x update_git_repo.sh
```
#### Windows

Copy the script ```update_repo.bat``` to your repository source directory.


### Step 3 

Run the script by providing your github username followed by the repository name.  

#### *nix

```usage: ./update_git_repo.sh <USER> <REPO>```

#### Windows

```usage: ./update_git_repo.bat <USER> <REPO>```

-------------
## Note: 
Recommend adding `*.sh` and `*.bat` to your .gitignore file so the script is not tracked and uploaded.

*Ref: 
<https://help.github.com/en/github/using-git/ignoring-files>*

### Basic Setup
-------------
The following commands are done using [gitbash](https://gitforwindows.org/).

Set your global config parameters

```text
git config --global user.email <NUM>+<USER>@users.noreply.github.com
git config --global user.user <USER>
```

**Create the .global_ignore file**

\*nix: ```touch ~/.gitignore_global```

Windows: ```notepad $HOME/.gitignore_global```

\
**Add .gitignore_global to your config file**

\*nix: ```git config --global core.excludesfile ~/.gitignore_global```

Windows: ```git config --global core.excludesfile $HOME/.gitignore_global```


*Things to check if gitignore is not working: 
<https://stackoverflow.com/questions/7529266/git-global-ignore-not-working/22835691#22835691>*
