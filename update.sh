#!/bin/bash

# Bash script to update Linux

# Colors for text output
red=""; green=""; yellow=""; normal=""
if [ -t 1 ]; then
  red=$( tput setaf 1 )
  green=$( tput setaf 2 )
  yellow=$( tput setaf 3 )
  normal=$( tput sgr 0 )
fi

# Log file
updatelog="/var/log/update.log"

# Get Linux distribution
linuxdistro=$(grep '^ID=' /etc/os-release | sed 's/ID=//g')

# Help screen
USAGE="
Usage: [sudo] ./update.sh [-fahy]
    -f   Run full-upgrade
    -a   Don't run autoremove
    -y   Reboot automatically if needed
    -h   Show this help screen
"

# Check command line args
while getopts ":fahy" OPT; do
  case ${OPT} in
    f ) dOn=1 ;;
    a ) aOff=1 ;;
    h ) hOn=1 ;;
    y ) yOn=1 ;;
    \? ) echo "${red}Unknown option: -${OPTARG}${normal}${USAGE}"; exit 1 ;;
  esac
done

# Show help screen
if [[ -n $hOn ]]; then
  echo "${normal}$USAGE${normal}"
  exit 2
fi

# Use sudo if user is not root
sudo_cmd=""
if [ "$(id -u)" -ne 0 ]; then
  if ! command -v sudo > /dev/null; then
    echo "${red}
This script must be run as root or by a user with sudo permissions.${normal}
"
    exit 1
  fi
  sudo_cmd=sudo
  # /var/log is not writable for normal users
  updatelog="${HOME}/update.log"
fi

# Non-interactive apt, keep existing config files on conflicts
apt_cmd="env DEBIAN_FRONTEND=noninteractive apt-get"
apt_opts="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

# Run a command, log its output and remember if it failed
failed=0
run() {
  "$@" | tee -a "${updatelog}"
  [ "${PIPESTATUS[0]}" -eq 0 ] || failed=1
}

# Start update
echo "${yellow}#####   Running linux update script   #####

Starting update: $(date)

Linux distribution: ${linuxdistro}${normal}" | tee "${updatelog}"

# Run apt update
echo -e "
${green}#####   Updating package database   #####${normal}" | tee -a "${updatelog}"
run ${sudo_cmd} ${apt_cmd} update --allow-releaseinfo-change

# Run apt upgrade / full-upgrade
if [[ -n $dOn ]]; then
# Run apt full-upgrade
  echo -e "
${green}#####   Upgrading OS - full upgrade   #####${normal}" | tee -a "${updatelog}"
  run ${sudo_cmd} ${apt_cmd} full-upgrade ${apt_opts}
else
# Run apt upgrade
  echo -e "
${green}#####   Upgrading OS   #####${normal}" | tee -a "${updatelog}"
  run ${sudo_cmd} ${apt_cmd} upgrade ${apt_opts}
fi

# Run apt autoremove
if [[ -z $aOff ]]; then
  echo -e "
${green}#####   Removing not needed packages   #####${normal}" | tee -a "${updatelog}"
  run ${sudo_cmd} ${apt_cmd} autoremove -y --purge
fi

# Run apt clean
echo -e "
${green}#####   Cleaning up   #####${normal}" | tee -a "${updatelog}"
run ${sudo_cmd} ${apt_cmd} clean

# Update pihole
if command -v pihole > /dev/null; then
echo -e "
${green}#####   Updating pihole   #####${normal}" | tee -a "${updatelog}"
run ${sudo_cmd} pihole -up
fi

# Check log
if [ -f "${updatelog}" ]; then
  echo -e "
${green}#####   Checking for actionable messages   #####${normal}" | tee -a "${updatelog}"
  grep -Ewi --color 'warning|error|critical|restart' "${updatelog}" | uniq
fi

# Update done
if [ ${failed} -ne 0 ]; then
  echo -e "
${red}#####   UPDATE FINISHED WITH ERRORS (see log)   #####${normal}
" | tee -a "${updatelog}"
else
  echo -e "
${green}#####   UPDATE DONE   #####${normal}
" | tee -a "${updatelog}"
fi
echo "
${yellow}Update done: $(date)${normal}" | tee -a "${updatelog}"

# Do reboot if needed
if [ -f /var/run/reboot-required ]; then
  echo -e "
${yellow}#####   Reboot required!   #####${normal}" | tee -a "${updatelog}"
  if [[ -n $yOn ]]; then
    echo -e "
${yellow}#####   ... REBOOTING ...   #####${normal}" | tee -a "${updatelog}"
    ${sudo_cmd} reboot
  else
    echo -e "
${yellow}#####   Please reboot machine manually.   #####${normal}" | tee -a "${updatelog}"
  fi
fi

echo -e "
${green}#####   Full log: ${updatelog}   #####${normal}"

# The end
exit ${failed}
