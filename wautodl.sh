#!/bin/bash
VER=1.0
#################################################################################
#################################################################################
####                                                                         ####
#### Copyright (C) 2019  wuseman <wuseman@nr1.nu> - All Rights Reserved      ####
#### Created: 13/02/2019                                                     ####
####                                                                         ####
#### A notice to all nerds.                                                  ####
#### If you will copy developers real work it will not make you a hacker.    ####
#### Resepect all developers, we doing this because it's fun!                ####
####                                                                         ####
#################################################################################
#################################################################################

PORT="2323"                             # Set a prefered port
PASSWORD="odemnn"                       # Set a password
WWW="/var/www/html"                     # Apache/Nginx path (Usually: /var/www/html)

DISTRO=$(cat /etc/*release | head -n 1 | awk '{ print tolower($1) }' | cut -d= -f2)

RTORRENT="/usr/bin/rtorrent"
IRSSI="/usr/bin/irssi"

banner() {
cat << "EOF"
                       __            ____
 _      ______ ___  __/ /_____  ____/ / /
| | /| / / __ `/ / / / __/ __ \/ __  / /
| |/ |/ / /_/ / /_/ / /_/ /_/ / /_/ / /
|__/|__/\__,_/\__,_/\__/\____/\__,_/_/

EOF
}



if [[ ! -x  $RTORRENT ]]; then
if [[ $EUID -eq "0" ]]; then
 clear; banner
 printf "rtorrent is required to be installed before you can run\n"
 read -p "this script, do you want to install rtorrent (y/N): " installrtorrent
  case $installrtorrent in
    y) if [[ $DISTRO = "gentoo" ]]; then emerge --ask rtorrent;exit 0;fi
       if [[ $DISTRO = "sabayon" ]]; then emerge --ask rtorrent;exit 0;fi
       if [[ $DISTRO = "ubuntu" ]]; then apt-get install rtorrent -qq -y; exit 0;fi
       if [[ $DISTRO = "debian" ]]; then apt-get install rtorrent;exit 0;fi
       if [[ $DISTRO = "mint" ]]; then apt-get install rtorrent;exit 0;fi
       if [[ -n $DISTRO ]]; then echo "wautodl is not supported for $DISTRO, please install rtorrent manually."; exit 0; fi ;;
    N) exit 0 ;;
    \?) echo "Please enter a proper answer y=yes N=no" ;;
  esac
 else
 banner; printf "you must run this script as root since rtorrent is required to be installed.\n\n"
 exit
fi
fi


if [[ ! -x  $IRSSI ]]; then
if [[ $EUID -eq "0" ]]; then
clear; banner
printf "irssi is required to be installed before you can run\n"
read -p "this script, do you want to install irssi (y/N): " installirssi
 case $installirssi in
   y) if [[ $DISTRO = "gentoo" ]]; then emerge --ask irssi;exit 0;fi
      if [[ $DISTRO = "sabayon" ]]; then emerge --ask irssi;exit 0;fi
      if [[ $DISTRO = "ubuntu" ]]; then apt-get install irssi -qq -y; exit 0;fi
      if [[ $DISTRO = "debian" ]]; then apt-get install irssi;exit 0;fi
      if [[ $DISTRO = "mint" ]]; then apt-get install irssi;exit 0;fi
      if [[ -n $DISTRO ]]; then echo "wautodl is not supported for $DISTRO, please install irssi manually."; exit 0; fi ;;
   N) exit 0 ;;
   \?) echo "Please enter a proper answer y=yes N=no" ;;
esac
 else
 banner; printf "you must run this script as root since irssi is required to be installed.\n\n"
fi
fi

if [[ $EUID -lt "1" ]]; then
echo "Don't run this script by root.."
exit 1
fi

set -eo pipefail


if [[ -z $PORT ]]; then
printf "You must set a prefered port in $basename$0.\n"
exit 0
fi

if [[ -z $PASSWORD ]]; then
printf "You must set a password in $basename$0\n"
exit 0
fi

if [[ -z $WWW ]]; then
printf "You must set your apache/nginx folder in $basename$0\n"
exit 0
fi

help() {
banner
cat << "EOF"

wautodl - a simple bash script for setup autodl-irssi and ruTorrent on any linux distro

      i) INSTALL     - Install ruTorrent, irssi and autodl-irssi
      u) UNINSTALL   - Remove ruTorrent,irssi and autodl-irssi incl. all data

EOF
}

cronAdd() {
    tmpcron="$(mktemp)"
}


rutorrent-install() {
clear
banner
if [[ ! $(stat --format "%U:%G" /var/www/html/) = "www-data:www-data" ]]; then 
echo "You must set correct permission of $WWW, aborted"
exit 1
fi
if [[ ! -d $WWW/rutorrent ]]; then
  printf "Downloading and installing ruTorrent, please wait..\n\n"
  cd $WWW
  git clone https://github.com/Novik/ruTorrent &> /dev/null
  printf "ruTorrent was successfully installed..\n\n"
  mv $WWW/ruTorrent $WWW/rutorrent
  chmod 777 /var/www/html/rutorrent/share/settings
  chmod 777 /var/www/html/rutorrent/share/torrents
else
  sleep 0
fi
}
autodl-irssi-install() {
pkill -u $(whoami) 'irssi' || true
printf "Please wait, downloading autodl-irssi..\n"
mkdir -p ~/.irssi/scripts/autorun
git clone https://github.com/autodl-community/autodl-irssi
cd autodl-irssi
cp autodl-irssi.pl ~/.irssi/scripts/autorun/
mkdir -p ~/.autodl
if [[ -f ~/.autodl/autodl.cfg ]]; then
   printf "\nCreated a autodl.cfg.bak for you in ~/.autodl"
   cp ~/.autodl/autodl.cfg ~/.autodl/autodl.cfg.bak-"$(date +"%d.%m.%y@%H:%M:%S")"
fi
echo "[options]
gui-server-port = $PORT
gui-server-password = $PASSWORD" > ~/.autodl/autodl.cfg
if [[ "$(crontab -l 2> /dev/null | grep -oc '^\@reboot screen -dmS autodl irssi$')" == "0" ]]; then
 printf "\nAutodl irssi has been successfully been installed\n"
 printf "\nAdded a new cron event for you..\n\n"
 cronAdd
 crontab -l 2> /dev/null > "$tmpcron" || true
 echo '@reboot screen -dmS autodl irssi' >> "$tmpcron"
 echo '@reboot screen -dmS rtorrent rtorrent' >> "$tmpcron"

 crontab "$tmpcron"
 rm "$tmpcron"
else
 printf "\n\nThis cron job already exists in the crontab\n\n"
fi
 printf "Starting up autodl-irssi in a screen, use 'screen -rd irssi' to join irssi\n\n"
screen -dmS irssi irssi
screen -dmS rtorrent rtorrent
 cd /var/www/html/rutorrent/plugins
 printf "Successfully configured autodl."
 printf "\n\nEverything has been successfully installed.\n\n"
 printf "Visit: \e[1;32mhttp://<localip>/rutorrent\e[0m and enjoy your new install\n\n" 
 git clone https://github.com/autodl-community/autodl-rutorrent.git autodl-irssi  &> /dev/null
 chown -R www-data:www-data $WWW/rutorrent/plugins/autodl-irssi &> /dev/null
 mv $WWW/rutorrent/plugins/autodl-irssi/_conf.php $WWW/rutorrent/plugins/autodl-irssi/conf.php
 sed -i "s/0/$PORT/g" $WWW/rutorrent/plugins/autodl-irssi/conf.php
 sed -i "s/\"\";/\"$PASSWORD\";/g" $WWW/rutorrent/plugins/autodl-irssi/conf.php
}

autodl-remove() {
clear
banner
printf "Are you sure you want to uninstall\n"; read -p "autodl-irssi and remove all data (Y/n): " CONFIRM
if [[ $CONFIRM =~ ^[Y]$ ]]; then
if [[ ! -d ~/.autodl ]]; then
  printf "\nautodl-irssi seems not to be installed, aborted\n\n"
  exit
elif [[ ! -d $WWW/rutorrent/plugins/autodl-irssi ]]; then
  printf "\nautodl-irssi-ruTorrent seems not to be installed, aborted\n\n"
  exit
else
  pkill -u $(whoami) 'SCREEN -dmS autodl irssi' || true; sleep 2
  rm -rf ~/.autodl ~/.irssi $WWW/rutorrent
  crontab -u $(whoami) -l | grep -v '@reboot screen -dmS autodl irssi' | crontab -u $(whoami) -
  crontab -u $(whoami) -l | grep -v '@reboot screen -dmS rtorrent rtorrent' | crontab -u $(whoami) -
  printf "\nAutodl irssi has successfully been uninstalled\n\n"
fi
else
  printf "Aborted..\n"
fi
}

if [[ -z $1 ]]; then
help
fi

while getopts ":iuh" getopt; do
  case $getopt in
         i) rutorrent-install; autodl-irssi-install ;;
         u) autodl-remove ;;
         h) help ;;
  esac
done



