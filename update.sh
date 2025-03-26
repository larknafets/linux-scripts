#!/bin/bash

# Bash script to update Linux

# Colors for text output
red=$( tput setaf 1 );
green=$( tput setaf 2 );
yellow=$( tput setaf 3 );
normal=$( tput sgr 0 );

# Log file
updatelog="/tmp/update.log"

# Get Linux distribution
linuxdistro=`grep '^ID=' /etc/os-release | sed 's/ID=//g'`

# Help screen
USAGE="
Usage: [sudo] ./update.sh [-frahy]
    -f   Run full-upgrade
    -r   Run do-release-upgrade (Ubuntu)
    -a   Don't run autoremove
    -y   Reboot automatically if needed
    -h   Show this help screen
"

# Check command line args
while getopts ":frahy" OPT; do
  case ${OPT} in
    f ) dOn=1 ;;
    r ) rOn=1 ;;
    a ) aOff=1 ;;
    h ) hOn=1 ;;
    y ) yOn=1 ;;
  esac
done

# Check whether script is being run as root/sudo
if [ $(id -u) -ne 0 ]; then
  echo "${red}
This script must be run as root or with sudo permissions.${normal}
"
  exit 1
fi

# run sudo command before command if user is not root
sudo_cmd=""
if [ `whoami` != root ]; then
  sudo_cmd=sudo
fi

# Show help screen
if [[ -n $hOn ]]; then
  echo "${normal}$USAGE${normal}"
  exit 2
fi

# Start update
echo "${yellow}#####   Running linux update script   #####

Starting update: `date`

Linux distribution: ${linuxdistro}${normal}" | tee ${updatelog}

# Run apt update
echo -e "
${green}#####   Updating package database   #####${normal}" | tee -a ${updatelog}
${sudo_cmd} apt update --allow-releaseinfo-change -y | tee -a ${updatelog}

# Run apt upgrade / full-upgrade
if [[ -n $dOn ]]; then
# Run apt full-upgrade
  echo -e "
${green}#####   Upgrading OS - full upgrade   #####${normal}" | tee -a ${updatelog}
  ${sudo_cmd}  apt full-upgrade -y | tee -a ${updatelog}
else
# Run apt upgrade
  echo -e "
${green}#####   Upgrading OS   #####${normal}" | tee -a ${updatelog}
  ${sudo_cmd}  apt upgrade -y | tee -a ${updatelog}
fi

# Run apt autoremove
if [[ -z $aOff ]]; then
  echo -e "
${green}#####   Starting autoremove   #####${normal}" | tee -a ${updatelog}
  ${sudo_cmd}  apt autoremove -y --purge | tee -a ${updatelog}
fi

# Run apt autoclean and clean
echo -e "
${green}#####   Cleaning up   #####${normal}" | tee -a ${updatelog}
${sudo_cmd}  apt autoclean -y | tee -a ${updatelog}
${sudo_cmd}  apt clean | tee -a ${updatelog}

# Update pihole and gravity-sync
if [ -f /usr/local/bin/pihole ]; then
echo -e "
${green}#####   Updating pihole and gravity-sync   #####${normal}" | tee -a ${updatelog}
${sudo_cmd}  pihole -up | tee -a ${updatelog}
  if [ -f /usr/local/bin/gravity-sync ]; then
    ${sudo_cmd}  gravity-sync update | tee -a ${updatelog}
  fi
fi

# Run do-release-upgrade for Ubuntu
if [[ -n $rOn ]]; then
  if [ "${linuxdistro}" = "ubuntu" ]; then
    echo -e "
${green}#####   Starting release upgrade (Ubuntu)   #####${normal}" | tee -a ${updatelog}
    ${sudo_cmd}  do-release-upgrade -f DistUpgradeViewNonInteractive | tee -a ${updatelog}
  fi
fi

# Check log
if [ -f ${updatelog} ]; then
  echo -e "
${green}#####   Checking for actionalbe messages   #####${normal}" | tee -a ${updatelog}
  egrep -wi --color 'warning|error|critical|reboot|restart|autoclean|autoremove' ${updatelog} | uniq
  echo -e "
${green}#####   Full log: ${updatelog}   #####${normal}"
fi

# Update done
echo -e "
${green}#####   UPDATE DONE   #####${normal}
" | tee -a ${updatelog}
echo "
${yellow}Update done: `date`${normal}" | tee -a ${updatelog}

# Do reboot if needed
if [ -f /var/run/reboot-required ]; then
  echo -e "
${yellow}#####   Reboot required!   #####${normal}" | tee -a ${updatelog}
  if [[ -n $yOn ]]; then
    echo -e "
${yellow}#####   ... REBOOTING ...   #####${normal}" | tee -a ${updatelog}
    ${sudo_cmd}  reboot
  else
    echo -e "
${yellow}#####   Please reboot machine manually.   #####${normal}" | tee -a ${updatelog}
  fi
fi

# The end
exit 0