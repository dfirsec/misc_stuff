@echo off

set USER=%1
set REPO=%2

rem Must provide at least two arguments
if "%2" == "" (
    echo.
    echo Usage: %0 ^<USER^> ^<REPO^>
    exit /b
) else (
    goto backup
)

:backup
rem Check if 7zip is installed
if not exist "C:\Program Files\7-Zip\7z.exe" (
    echo.
    echo Error: Script requires 7zip but it's not installed.
    exit /b
) else (
    cls
    echo.
    set hr=%time:~0,2%
    if %hr% LSS 10 (
        set hr=0%hr:~1,1%
    )
    set TODAY=%date:~7,2%-%date:~4,2%-%date:~10,4%-%hr%%time:~3,2%%time:~6,2%%time:~9,2%
    
    rem Create repo backup
    set SRC=%~dp0
    echo [+] Backing up to %USERPROFILE%
    "C:\Program Files\7-Zip\7z.exe" a -tzip "%USERPROFILE%\%REPO%_repo_%TODAY%.zip" %SRC% -mx5 >NUL 2>&1
    echo [+] Backup finished!
    pause
    goto gitrun
)

:gitrun
rem Remove all files from git cache
echo [+] Initiating repo reset
echo.
call git rm -r --cached .
call git add .
call git commit -am "Refreshing .gitignore"

rem Check out to a temporary branch:
call git checkout --orphan TEMP_BRANCH

rem Add all the files:
call git add -A

rem Commit the changes:
call git commit -am "Initial commit"

rem Delete the old branch:
call git branch -D master

rem Rename the temporary branch to master:
call git branch -m master

rem Switch to SSH:
call git remote set-url origin git@github.com:%USER%/%REPO%.git

rem Finally, force update to our repository:
call git push -f origin master

echo.
echo Done!
