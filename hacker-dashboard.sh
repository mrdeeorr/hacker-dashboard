#!/usr/bin/env bash
# ===========================================================
# Hacker Dashboard — Universal (Termux + Linux) Single Script
# Safe-by-default guided pentest helper (no automatic attacks)
# Author: mrdeeorr (adapted)
# Version: 1.0
# ===========================================================
set -euo pipefail

# ----------------------------
# Config & directories
# ----------------------------
HOME_DIR="${HOME:-/root}"
LOG_DIR="$HOME_DIR/logs"
REPORT_DIR="$HOME_DIR/hacker-reports"
TOOLS_DIR="$HOME_DIR/.hacker-tools"
REPO_RAW_URL="https://raw.githubusercontent.com/mrdeeorr/hacker-dashboard/main/hacker-dashboard.sh"
INSTALL_PATH="/usr/local/bin/hacker-dashboard"   # default install path (will adapt for Termux)
if [[ "$(uname -o 2>/dev/null || true)" = "Android" ]]; then
  INSTALL_PATH="/data/data/com.termux/files/usr/bin/hacker-dashboard"
fi

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$TOOLS_DIR"

# ----------------------------
# Colors
# ----------------------------
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"

# ----------------------------
# Utility logging
# ----------------------------
log_action() {
  mkdir -p "$LOG_DIR"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_DIR/actions.log"
}

log_git() {
  mkdir -p "$LOG_DIR"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_DIR/git.log"
}

# ----------------------------
# Detect package manager (universal)
# ----------------------------
detect_pkg_mgr() {
  if command -v pkg >/dev/null 2>&1; then echo "pkg"; return; fi   # Termux pkg wrapper
  if command -v apt-get >/dev/null 2>&1; then echo "apt"; return; fi
  if command -v yum >/dev/null 2>&1; then echo "yum"; return; fi
  if command -v dnf >/dev/null 2>&1; then echo "dnf"; return; fi
  if command -v pacman >/dev/null 2>&1; then echo "pacman"; return; fi
  echo "unknown"
}

PKG_MGR="$(detect_pkg_mgr)"

install_with_pkg() {
  pkg="$1"
  case "$PKG_MGR" in
    pkg) pkg install -y "$pkg" ;;
    apt) sudo apt-get update && sudo apt-get install -y "$pkg" ;;
    yum) sudo yum install -y "$pkg" ;;
    dnf) sudo dnf install -y "$pkg" ;;
    pacman) sudo pacman -Syu --noconfirm "$pkg" ;;
    *) echo "Package manager not detected. Install $pkg manually." ;;
  esac
}

# ----------------------------
# Authorization guard
# ----------------------------
confirm_authorization() {
  cat <<EOF
${YELLOW}IMPORTANT: You must have explicit WRITTEN authorization to test any target.
Unauthorized testing is illegal and unethical.${RESET}

Type exactly: I_HAVE_AUTH
Or press Enter to cancel.
EOF
  read -r AUTH
  if [[ "$AUTH" != "I_HAVE_AUTH" ]]; then
    echo -e "${RED}Authorization not confirmed. Aborting action.${RESET}"
    log_action "Authorization not confirmed by user."
    return 1
  fi
  log_action "Authorization confirmed by user."
  return 0
}

# ----------------------------
# Helpers to create saved helper scripts (do not auto-run)
# ----------------------------
save_helper_script() {
  local name="$1"; shift
  local cmd="$*"
  mkdir -p "$REPORT_DIR"
  local file="$REPORT_DIR/${name}_$(date +%F_%H-%M-%S).sh"
  cat > "$file" <<EOF
#!/usr/bin/env bash
# Helper script for: $name
# Created: $(date)
# Read the command below. If you have authorization, run this script manually.
# Command:
$cmd
EOF
  chmod +x "$file"
  echo -e "${BLUE}Helper script saved to: $file${RESET}"
  log_action "Saved helper script: $file"
  echo "$file"
}

# ----------------------------
# Reporting helpers
# ----------------------------
new_report() {
  local tool="$1"
  mkdir -p "$REPORT_DIR"
  echo "$REPORT_DIR/${tool}_$(date +%F_%H-%M-%S).txt"
}

aggregate_reports() {
  local out="$REPORT_DIR/aggregated_report_$(date +%F_%H-%M-%S).txt"
  {
    echo "Pentest Aggregated Report"
    echo "Generated: $(date)"
    echo "================================"
    for f in "$REPORT_DIR"/*.txt; do
      [[ -f "$f" ]] || continue
      echo
      echo "----- $f -----"
      sed -n '1,200p' "$f"
    done
  } > "$out"
  echo -e "${GREEN}Aggregated report created: $out${RESET}"
  log_action "Created aggregated report $out"
}

export_reports_zip() {
  local zipfile="$REPORT_DIR/reports_$(date +%F_%H-%M-%S).zip"
  (cd "$REPORT_DIR" && zip -r "$zipfile" .) >/dev/null 2>&1 || true
  echo -e "${GREEN}Reports archived: $zipfile${RESET}"
  log_action "Reports archived to $zipfile"
}

# ----------------------------
# Git submenu (safe)
# ----------------------------
github_clone() {
  read -p "Git repo URL to clone: " url
  git clone "$url"
  log_git "clone $url"
}
github_pull() {
  read -p "Local repo path to pull: " path
  if [[ ! -d "$path/.git" ]]; then echo -e "${RED}Not a git repo:$path${RESET}"; return 1; fi
  (cd "$path" && git pull)
  log_git "pull $path"
}
github_commit_push() {
  read -p "Local repo path to commit & push: " path
  if [[ ! -d "$path/.git" ]]; then echo -e "${RED}Not a git repo:$path${RESET}"; return 1; fi
  read -p "Commit message: " msg
  (cd "$path" && git add . && git commit -m "$msg" && git push)
  log_git "commit/push $path : $msg"
}
github_status() {
  read -p "Local repo path to check status: " path
  if [[ ! -d "$path/.git" ]]; then echo -e "${RED}Not a git repo:$path${RESET}"; return 1; fi
  (cd "$path" && git status)
  log_git "status $path"
}

# ----------------------------
# Tool installers (ask first)
# ----------------------------
install_common_tools() {
  echo -e "${BLUE}Installing common, non-offensive utilities...${RESET}"
  install_with_pkg git || true
  install_with_pkg curl || true
  install_with_pkg wget || true
  install_with_pkg zip || true
  install_with_pkg unzip || true
  install_with_pkg python || true
  install_with_pkg nano || true
  echo -e "${GREEN}Common tools installed (if available).${RESET}"
  log_action "Installed common tools."
}

install_security_tools_prompt() {
  echo -e "${YELLOW}This will install security tools (nmap, sqlmap, hydra, nikto, aircrack-ng, metasploit etc.).${RESET}"
  echo -e "${YELLOW}These tools can be used for legitimate pentesting but also for abuse.${RESET}"
  read -p "Install security tools now? (y/N): " yn
  if [[ "$yn" != "y" ]]; then echo "Skipped."; return; fi
  echo -e "${BLUE}Installing selected security tools...${RESET}"
  # Try reasonable names across package managers
  install_with_pkg nmap || true
  install_with_pkg sqlmap || true
  install_with_pkg hydra || true
  install_with_pkg nikto || true
  install_with_pkg aircrack-ng || true
  # Metasploit may be packaged differently across distros; skip automatic heavy installs
  echo -e "${YELLOW}Note: Metasploit install may be manual on some systems; see docs.${RESET}"
  log_action "User installed security tools."
  echo -e "${GREEN}Security tools installation attempted.${RESET}"
}

# ----------------------------
# Guided (safe) modules — they PRINT recommended commands and SAVE helpers
# ----------------------------
guided_nmap_recon() {
  if ! confirm_authorization; then return 1; fi
  read -p "Target (IP or domain): " target
  local report
  report="$(new_report nmap)"
  local cmd="nmap -sS -sV -A -oN \"$report\" \"$target\""
  save_helper_script "nmap_recon_$target" "$cmd"
  echo -e "${YELLOW}Recommended nmap command:${RESET}\n$cmd"
  echo "Saved helper script in $REPORT_DIR. Run it manually if authorized."
}

guided_subdomains() {
  if ! confirm_authorization; then return 1; fi
  read -p "Domain (example.com): " domain
  local report
  report="$(new_report subdomains)"
  local cmd="amass enum -d \"$domain\" -o \"$report\""
  save_helper_script "amass_enum_$domain" "$cmd"
  echo -e "${YELLOW}Recommended amass command:${RESET}\n$cmd"
}

guided_web_tests() {
  if ! confirm_authorization; then return 1; fi
  read -p "Target URL (http[s]://...): " url
  local nikto_report sqlmap_dir
  nikto_report="$(new_report nikto)"
  sqlmap_dir="$REPORT_DIR/sqlmap_$(date +%F_%H-%M-%S)"
  local cmd1="nikto -host \"$url\" -output \"$nikto_report\""
  local cmd2="sqlmap -u \"$url\" --batch --output-dir=\"$sqlmap_dir\""
  save_helper_script "nikto_$url" "$cmd1"
  save_helper_script "sqlmap_$url" "$cmd2"
  echo -e "${YELLOW}Nikto command:${RESET}\n$cmd1"
  echo -e "${YELLOW}SQLMap command:${RESET}\n$cmd2"
}

guided_wireless() {
  if ! confirm_authorization; then return 1; fi
  echo -e "${YELLOW}Wireless commands will be prepared. You must run them manually in monitor mode (iwconfig/airmon-ng).${RESET}"
  read -p "Interface (e.g. wlan0): " iface
  local capture="$REPORT_DIR/wifi_capture_$(date +%F_%H-%M-%S)"
  local cmd1="airodump-ng --write \"$capture\" $iface"
  local cmd2="aircrack-ng \"${capture}-01.cap\" -w /path/to/wordlist.txt"
  save_helper_script "airodump_$iface" "$cmd1"
  save_helper_script "aircrack_$iface" "$cmd2"
  echo -e "${YELLOW}Saved wireless helper scripts. Run them manually with authorization.${RESET}"
}

guided_bruteforce() {
  if ! confirm_authorization; then return 1; fi
  read -p "Target host/IP: " host
  read -p "Service (ssh/ftp/http-form): " service
  read -p "Username (leave blank to try many): " user
  read -p "Wordlist full path: " wordlist
  local cmd
  if [[ -z "$user" ]]; then
    cmd="hydra -P \"$wordlist\" \"$host\" $service"
  else
    cmd="hydra -l \"$user\" -P \"$wordlist\" \"$host\" $service"
  fi
  save_helper_script "hydra_${host}_${service}" "$cmd"
  echo -e "${YELLOW}Hydra helper saved. Command:\n$cmd${RESET}"
}

guided_payload_helper() {
  if ! confirm_authorization; then return 1; fi
  read -p "Payload (example: android/meterpreter/reverse_tcp): " payload
  read -p "LHOST (your IP): " lhost
  read -p "LPORT (port): " lport
  local out="$REPORT_DIR/payload_$(date +%F_%H-%M-%S)"
  local cmd="msfvenom -p $payload LHOST=$lhost LPORT=$lport -o \"$out\""
  save_helper_script "msfvenom_payload" "$cmd"
  echo -e "${YELLOW}msfvenom helper saved. Command:\n$cmd${RESET}"
}

# ----------------------------
# Misc helpers
# ----------------------------
show_logs() { ls -lh "$LOG_DIR" || echo "No logs."; }
clean_temp() { rm -rf /tmp/* || true; echo "Temp cleaned."; log_action "clean_temp"; }

self_update_script() {
  echo -e "${BLUE}Downloading latest script (for manual review)...${RESET}"
  curl -s -o /tmp/hacker-dashboard.sh "$REPO_RAW_URL"
  if [[ -s /tmp/hacker-dashboard.sh ]]; then
    echo -e "${GREEN}Downloaded to /tmp/hacker-dashboard.sh${RESET}"
    read -p "Replace installed script at $INSTALL_PATH now? (y/N): " yn
    if [[ "$yn" == "y" ]]; then
      sudo mv /tmp/hacker-dashboard.sh "$INSTALL_PATH" 2>/dev/null || mv /tmp/hacker-dashboard.sh "$INSTALL_PATH"
      chmod +x "$INSTALL_PATH" || true
      log_action "Script updated to $INSTALL_PATH"
      echo -e "${GREEN}Updated.${RESET}"
    else
      echo "Canceled."
    fi
  else
    echo -e "${RED}Failed to download update.${RESET}"
  fi
}

enable_autostart() {
  local shellrc
  shellrc="${SHELL##*/}"
  case "$shellrc" in
    bash) rcfile="$HOME_DIR/.bashrc" ;;
    zsh) rcfile="$HOME_DIR/.zshrc" ;;
    *) rcfile="$HOME_DIR/.profile" ;;
  esac
  if ! grep -Fq "hacker-dashboard" "$rcfile" 2>/dev/null; then
    echo "bash $PWD/$(basename "$0")" >> "$rcfile"
    echo -e "${GREEN}Added autostart entry to $rcfile${RESET}"
    log_action "Enabled autostart in $rcfile"
  else
    echo "Autostart already present in $rcfile"
  fi
}

uninstall_local() {
  read -p "Remove reports/logs and uninstall script? (y/N): " yn
  if [[ "$yn" == "y" ]]; then
    rm -rf "$REPORT_DIR" "$LOG_DIR" "$TOOLS_DIR"
    # attempt to remove installed binary
    if [[ -f "$INSTALL_PATH" ]]; then rm -f "$INSTALL_PATH"; fi
    echo "Local files removed."
    log_action "Uninstalled locally"
  else
    echo "Canceled."
  fi
}

# ----------------------------
# Main interactive menu
# ----------------------------
while true; do
  clear
  cat <<EOF
${BLUE}==================================================${RESET}
            HACKER DASHBOARD — UNIVERSAL
${BLUE}==================================================${RESET}
  1) Install common utilities
  2) Install security tools (optional)
  3) Recon — guided Nmap (saves helper)
  4) Subdomain enumeration — guided
  5) Web tests — guided (Nikto + SQLMap helpers)
  6) Wireless guidance (airodump/aircrack helpers)
  7) Bruteforce helper (hydra) — guided
  8) Payload helper (msfvenom) — guided
  9) Aggregate reports
 10) Export reports ZIP
 11) Show logs
 12) Clean /tmp
 13) GitHub Quick Menu (clone/pull/commit/push/status)
 14) Enable autostart of dashboard at login
 15) Uninstall local files & script
 16) Self-update (download script to /tmp for review)
 17) Exit
${BLUE}==================================================${RESET}
EOF

  read -rp "Choose an option: " opt
  case "$opt" in
    1) install_common_tools ;;
    2) install_security_tools_prompt ;;
    3) guided_nmap_recon ;;
    4) guided_subdomains ;;
    5) guided_web_tests ;;
    6) guided_wireless ;;
    7) guided_bruteforce ;;
    8) guided_payload_helper ;;
    9) aggregate_reports ;;
    10) export_reports_zip ;;
    11) show_logs ;;
    12) clean_temp ;;
    13)
       PS3="Git Menu: "
       select g in "Clone" "Pull" "Commit & Push" "Status" "Back"; do
         case "$g" in
           "Clone") github_clone; break;;
           "Pull") github_pull; break;;
           "Commit & Push") github_commit_push; break;;
           "Status") github_status; break;;
           "Back") break;;
           *) echo "Invalid";;
         esac
       done
       ;;
    14) enable_autostart ;;
    15) uninstall_local ;;
    16) self_update_script ;;
    17) echo "Goodbye."; exit 0 ;;
    *) echo -e "${RED}Invalid option${RESET}" ;;
  esac

  echo
  read -rp "Press Enter to continue..." _dummy
done