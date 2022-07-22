#!/usr/bin/env bash

formatbytes() {
    b=${1:-0}
    d=''
    s=0
    S=(Bytes {K,M,G,T,E,P,Y,Z}B)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        ((s++))
    done
    echo "$b$d ${S[$s]} of space was cleaned up"
}

sudo -v

# Keep-alive sudo until `mac_cleanup.sh` has finished
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

preclean=$(df / | tail -1 | awk '{print $4}')

echo -e '\e[38;5;82m[+]\e[0m' 'Empty the Trash on all mounted volumes and the main HDD...'
sudo rm -rfv /Volumes/*/.Trashes/* &>/dev/null
sudo rm -rfv ~/.Trash/* &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Clear System Log Files...'
sudo rm -rfv /private/var/log/asl/*.asl &>/dev/null
sudo rm -rfv /Library/Logs/DiagnosticReports/* &>/dev/null
sudo rm -rfv /Library/Logs/Adobe/* &>/dev/null
rm -rfv ~/Library/Containers/com.apple.mail/Data/Library/Logs/Mail/* &>/dev/null
rm -rfv ~/Library/Logs/CoreSimulator/* &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Clear Adobe Cache Files...'
sudo rm -rfv ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files/* &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup iOS Applications...'
rm -rfv ~/Music/iTunes/iTunes\ Media/Mobile\ Applications/* &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Remove iOS Device Backups...'
rm -rfv ~/Library/Application\ Support/MobileSync/Backup/* &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup XCode Derived Data and Archives...'
rm -rfv ~/Library/Developer/Xcode/DerivedData/* &>/dev/null
rm -rfv ~/Library/Developer/Xcode/Archives/* &>/dev/null

# ----[ Caches ]----
echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup pip cache...'
rm -rfv ~/Library/Caches/pip &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup go cache...'
rm -rfv ~/Library/Caches/go-build &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Keybase cache...'
rm -rfv ~/Library/Caches/Keybase &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Safari cache...'
rm -rfv ~/Library/Caches/com.apple.Safari &>/dev/null
rm -rfv ~/Library/Caches/com.apple.Safari.SafeBrowsing &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Firefox cache...'
rm -rfv ~/Library/Caches/org.mozilla.firefox &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Google Chrome cache...'
rm -rfv ~/Library/Caches/Google/Chrome &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Thunderbird cache...'
rm -rfv ~/Library/Caches/Thunderbird &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Brave Browser cache...'
rm -rfv ~/Library/Caches/BraveSoftware &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Spotify cache...'
rm -rfv ~/Library/Caches/com.spotify.client &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Jedi cache...'
rm -rfv ~/Library/Caches/Jedi &>/dev/null

echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup VisualStudio TempDownload cache...'
rm -rfv ~/Library/Caches/VisualStudio/7.0/TempDownload &>/dev/null

if type "brew" &>/dev/null; then
    echo -e '\e[38;5;82m[+]\e[0m' 'Update Homebrew Recipes...'
    brew update
    echo -e '\e[38;5;82m[+]\e[0m' 'Upgrade and remove outdated formulae'
    brew upgrade
    echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Homebrew Cache...'
    brew cleanup -s &>/dev/null
    #brew cask cleanup &>/dev/null
    rm -rfv "$(brew --cache)" &>/dev/null
    brew tap --repair &>/dev/null
fi

if type "gem" &>/dev/null; then
    echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup any old versions of gems'
    gem cleanup &>/dev/null
fi

if type "docker" &>/dev/null; then
    rep=$(curl -s --unix-socket /var/run/docker.sock http://ping >/dev/null)
    status=$?
    if [ "$status" == "7" ]; then
        echo -e '\e[38;5;226m[-]\e[0m' 'Docker is not running'
    else
        echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Docker'
        docker system prune -af
    fi
fi

if [ "$PYENV_VIRTUALENV_CACHE_PATH" ]; then
    echo -e '\e[38;5;82m[+]\e[0m' 'Removing Pyenv-VirtualEnv Cache...'
    rm -rfv "$PYENV_VIRTUALENV_CACHE_PATH" &>/dev/null
fi

if type "npm" &>/dev/null; then
    echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup npm cache...'
    npm cache clean --force
fi

if type "yarn" &>/dev/null; then
    echo -e '\e[38;5;82m[+]\e[0m' 'Cleanup Yarn Cache...'
    yarn cache clean --force
fi

echo -e '\e[38;5;82m[+]\e[0m' 'Purge inactive memory...'
sudo purge

echo -e '\e[38;5;14m[*]\e[0m' 'Success!'

postclean=$(df / | tail -1 | awk '{print $4}')
count=$((preclean - postclean))
#count=$(( $count * 512))
formatbytes $count
