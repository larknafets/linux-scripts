# linux-scripts

## update.sh

Linux update script.

Options:
    
    -d   Run full-upgrade (dist-upgrade)
    -r   Run do-release-upgrade (Ubuntu)
    -a   Don't run autoremove
    -y   Reboot automatically if needed
    -h   Show this help screen

If no option is selected update, upgrade, autoremove and clean is being run only.

Pi-hole and gravity-sync will be updated if installed.

Log messages are saved to /temp/update.log additionally. The log file is cleared on every run.

Run command from git:

    curl https://raw.githubusercontent.com/larknafets/linux-scripts/main/update.sh | sudo bash -s -- -h