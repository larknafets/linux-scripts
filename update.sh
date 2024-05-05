#!/bin/bash

# Bash script to update Linux

# Colors for text output
red=$( tput setaf 1 );
green=$( tput setaf 2 );
yellow=$( tput setaf 3 );
normal=$( tput sgr 0 );

# Logfile
updatelog="/tmp/update.log"

# Get Linux distribution
linuxdistro=`grep '^ID=' /etc/os-release | sed 's/ID=//g'`

# Help screen
USAGE="
Usage: sudo ./update.sh [-drahy]
    -d   Run apt full-upgrade (dist-upgrade)
    -r   Run apt do-release-upgrade (Ubuntu)
    -a   Don't run apt autoremove
    -y   Reboot automatically if needed
    -h   Show this help screen
"

# Check command line args
while getopts ":drahy" OPT; do
  case ${OPT} in
    d ) dOn=1 ;;
    r ) rOn=1 ;;
    a ) aOff=1 ;;
    h ) hOn=1 ;;
    y ) yOn=1 ;;
  esac
done

# Check whether script is being run as root
if [ ${UID} != 0 ]; then
  echo "${red}
This script must be run as root or with sudo permissions.
Please run using sudo.${normal}
"
  exit 1
fi

# Show help screen
if [[ -n $hOn ]]; then
  echo "${normal}$USAGE${normal}"
  exit 2
fi

# Start update
echo "Starting update: `date`

Linux distribution: ${linuxdistro}
" | tee ${updatelog}

# Run apt update
echo -e "
${green}#####   Updating packet database   #####${normal}
" | tee -a ${updatelog}
sudo apt update --allow-releaseinfo-change -y | tee -a ${updatelog}

# Run apt upgrade
echo -e "
${green}#####   Upgrading OS   #####${normal}
" | tee -a ${updatelog}
sudo apt upgrade -y | tee -a ${updatelog}

# Run apt full-upgrade
if [[ -n $dOn ]]; then
  echo -e "
${green}#####   Dist upgrade / full upgrade   #####${normal}
" | tee -a ${updatelog}
  sudo apt full-upgrade -y | tee -a ${updatelog}
fi

# Run apt autoremove
if [[ -n $aOff ]]; then
  echo -e "
${green}#####   Starting autoremove   #####${normal}
" | tee -a ${updatelog}
  sudo apt autoremove -y | tee -a ${updatelog}
fi

# Run apt autoclean and clean
echo -e "
${green}#####   Cleaning up   #####${normal}
" | tee -a ${updatelog}
sudo apt autoclean -y | tee -a ${updatelog}
sudo apt clean | tee -a ${updatelog}

# Update pihole and gravity-sync
if [ -f /usr/local/bin/pihole ]; then
echo -e "
${green}#####   Updating pihole and gravity-sync   #####${normal}
" | tee -a ${updatelog}
sudo pihole -up | tee -a ${updatelog}
  if [ -f /usr/local/bin/gravity-sync ]; then
    sudo gravity-sync update | tee -a ${updatelog}
  fi
fi

# Run do-release-upgrade for Ubuntu
if [[ -n $rOn ]]; then
  if [ "${linuxdistro}" = "ubuntu" ]; then
    echo -e "
${green}#####   Starting release upgrade (Ubuntu)   #####${normal}
" | tee -a ${updatelog}
    sudo do-release-upgrade -f DistUpgradeViewNonInteractive | tee -a ${updatelog}
  fi
fi

# Check log
if [ -f ${updatelog} ]; then
  echo -e "
${green}#####   Checking for actionalbe messages   #####${normal}
" | tee -a ${updatelog}
  egrep -wi --color 'warning|error|critical|reboot|restart|autoclean|autoremove' ${updatelog} | uniq
  echo -e "
${green}#####   Full log: ${updatelog}   #####${normal}
"
fi

# Update done
echo -e "
${green}#####   UPDATE DONE   #####${normal}
" | tee -a ${updatelog}
echo "
Update done: `date`
" | tee ${updatelog}

# Do reboot if needed
if [ -f /var/run/reboot-required ]; then
  echo -e "
${yellow}#####   Reboot required!   #####${normal}
" | tee -a ${updatelog}
  if [[ -n $yOn ]]; then
    echo -e "
${yellow}#####   ... REBOOTING ...   #####${normal}
" | tee -a ${updatelog}
    sudo reboot
  else
    echo -e "
${yellow}#####   Please reboot machine manually.   #####${normal}
" | tee -a ${updatelog}
  fi
fi

# The end
exit 0