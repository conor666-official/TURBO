#!/data/data/com.termux/files/usr/bin/bash

# ═══════════════════════════════════════════════════════════════════════
#  ████████╗██╗░░░██╗██████╗░██████╗░░█████╗░
#  ╚══██╔══╝██║░░░██║██╔══██╗██╔══██╗██╔══██╗
#  ░░░██║░░░██║░░░██║██████╔╝██████╔╝██║░░██║
#  ░░░██║░░░██║░░░██║██╔══██╗██╔══██╗██║░░██║
#  ░░░██║░░░╚██████╔╝██║░░██║██║░░██║╚█████╔╝
#  ░░░╚═╝░░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░
# ═══════════════════════════════════════════════════════════════════════
#  TURBO - PROFESSIONAL IP CHANGER
#  Version: 3.0 | Build: 666
#  Developer: XTREME K1 💀
#  Status: FULLY OPERATIONAL
# ═══════════════════════════════════════════════════════════════════════

# ==================== CONFIGURATION ====================
DEFAULT_INTERVAL=10
MIN_INTERVAL=3
MAX_INTERVAL=60
ROTATION_INTERVAL=$DEFAULT_INTERVAL
SCRIPT_DIR="$HOME/turbo"
TOR_DIR="$SCRIPT_DIR/.tor_cache"
PRIVOXY_DIR="$SCRIPT_DIR/.privoxy_cache"
PROXY="127.0.0.1:8118"
LOG_FILE="$SCRIPT_DIR/turbo.log"
CONFIG_FILE="$SCRIPT_DIR/turbo.conf"

# ==================== COLORS ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
ORANGE='\033[38;5;208m'
LIME='\033[38;5;154m'
PINK='\033[38;5;206m'
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# ==================== FUNCTIONS ====================

show_help() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${WHITE}                    TURBO IP CHANGER v3.0                     ${CYAN}║${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${GREEN}  Usage:${WHITE} turbo [OPTIONS]                                 ${CYAN}║${RESET}"
    echo -e "${CYAN}║                                                              ║${RESET}"
    echo -e "${CYAN}║${YELLOW}  Options:${RESET}                                                  ${CYAN}║${RESET}"
    echo -e "${CYAN}║    ${GREEN}-s, --seconds${WHITE} <num>    Set rotation interval (3-60s)     ${CYAN}║${RESET}"
    echo -e "${CYAN}║    ${GREEN}-h, --help${WHITE}             Show this help message            ${CYAN}║${RESET}"
    echo -e "${CYAN}║    ${GREEN}-v, --version${WHITE}          Show version information          ${CYAN}║${RESET}"
    echo -e "${CYAN}║    ${GREEN}-l, --log${WHITE}              Show rotation log                  ${CYAN}║${RESET}"
    echo -e "${CYAN}║    ${GREEN}-c, --clear${WHITE}             Clear log file                     ${CYAN}║${RESET}"
    echo -e "${CYAN}║                                                              ║${RESET}"
    echo -e "${CYAN}║${YELLOW}  Examples:${RESET}                                                ${CYAN}║${RESET}"
    echo -e "${CYAN}║    ${WHITE}turbo -s 5${RESET}              Change IP every 5 seconds        ${CYAN}║${RESET}"
    echo -e "${CYAN}║    ${WHITE}turbo -s 10${RESET}             Change IP every 10 seconds       ${CYAN}║${RESET}"
    echo -e "${CYAN}║    ${WHITE}turbo -s 30${RESET}             Change IP every 30 seconds       ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    exit 0
}

show_version() {
    echo -e "${CYAN}════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}TURBO IP CHANGER${RESET}"
    echo -e "${YELLOW}Version: 3.0${RESET}"
    echo -e "${YELLOW}Build: 666${RESET}"
    echo -e "${YELLOW}Developer: XTREME K1 💀${RESET}"
    echo -e "${CYAN}════════════════════════════════════════════${RESET}"
    exit 0
}

show_log() {
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${CYAN}════════════════════════════════════════════${RESET}"
        echo -e "${GREEN}ROTATION LOG:${RESET}"
        echo -e "${CYAN}════════════════════════════════════════════${RESET}"
        tail -50 "$LOG_FILE"
    else
        echo -e "${RED}No log file found.${RESET}"
    fi
    exit 0
}

clear_log() {
    > "$LOG_FILE"
    echo -e "${GREEN}Log cleared successfully.${RESET}"
    exit 0
}

check_dependencies() {
    local missing=()
    for cmd in tor privoxy curl nc; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[!] Missing dependencies: ${missing[*]}${RESET}"
        echo -e "${YELLOW}[*] Installing...${RESET}"
        pkg install ${missing[*]} netcat-openbsd -y 2>/dev/null
        sleep 2
    fi
}

cleanup_processes() {
    pkill -9 tor 2>/dev/null
    pkill -9 privoxy 2>/dev/null
    sleep 1
}

create_directories() {
    mkdir -p "$TOR_DIR" "$PRIVOXY_DIR" "$SCRIPT_DIR"
}

start_tor_instances() {
    local tor_ports=(9050 9060 9070 9080 9090)
    local control_ports=(9051 9061 9071 9081 9091)
    
    for i in ${!tor_ports[@]}; do
        local dir="$TOR_DIR/tor${tor_ports[$i]}"
        mkdir -p "$dir"
        cat > "$dir/torrc" <<EOF
SocksPort ${tor_ports[$i]}
ControlPort ${control_ports[$i]}
DataDirectory $dir
CookieAuthentication 0
ExitNodes {us},{ca},{uk},{de},{fr},{nl},{ch},{se}
StrictNodes 0
NumEntryGuards 2
CircuitBuildTimeout 30
LearnCircuitBuildTimeout 0
NewCircuitPeriod 15
MaxCircuitDirtiness 60
EOF
        tor -f "$dir/torrc" 2>/dev/null &
    done
}

start_privoxy() {
    local tor_ports=(9050 9060 9070 9080 9090)
    
    cat > "$PRIVOXY_DIR/config" <<EOF
listen-address 127.0.0.1:8118
toggle 1
enable-remote-toggle 0
enable-remote-http-toggle 0
buffer-limit 0
forward-socks5t / 127.0.0.1:9050 .
EOF
    
    for port in "${tor_ports[@]:1}"; do
        echo "forward-socks5t / 127.0.0.1:$port ." >> "$PRIVOXY_DIR/config"
    done
    
    privoxy "$PRIVOXY_DIR/config" 2>/dev/null &
}

rotate_tor_circuits() {
    local control_ports=(9051 9061 9071 9081 9091)
    for port in ${control_ports[@]}; do
        echo -e "AUTHENTICATE \"\"\r\nSIGNAL NEWNYM\r\nQUIT\r\n" | nc -w 2 127.0.0.1 $port 2>/dev/null
    done
}

get_current_ip() {
    local ip=""
    ip=$(curl -s --proxy http://$PROXY --max-time 5 --connect-timeout 3 "https://api.ipify.org" 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s --proxy http://$PROXY --max-time 4 "https://ifconfig.me/ip" 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s --proxy http://$PROXY --max-time 4 "https://icanhazip.com" 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s --proxy http://$PROXY --max-time 4 "https://checkip.amazonaws.com" 2>/dev/null)
    echo "${ip:-N/A}"
}

get_ip_location() {
    local location=""
    if command -v jq &>/dev/null; then
        location=$(curl -s --proxy http://$PROXY --max-time 5 "https://ipapi.co/json/" 2>/dev/null | jq -r '"\(.city), \(.country_name)"' 2>/dev/null)
    fi
    [[ -z "$location" ]] && location=$(curl -s --proxy http://$PROXY --max-time 4 "http://ip-api.com/json/?fields=city,country" 2>/dev/null | grep -oP '"city":"\K[^"]+' | head -1)
    echo "${location:-Unknown}"
}

get_network_info() {
    local net=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5}' | head -1)
    [[ -z "$net" ]] && net=$(ip link show 2>/dev/null | grep -v lo | grep -oP '^[0-9]+: \K\w+' | head -1)
    echo "${net:-Unknown}"
}

print_banner() {
    clear
    echo -e "${RED}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                                                                   ║
    ║      ████████╗██╗░░░██╗██████╗░██████╗░░█████╗░                  ║
    ║      ╚══██╔══╝██║░░░██║██╔══██╗██╔══██╗██╔══██╗                  ║
    ║      ░░░██║░░░██║░░░██║██████╔╝██████╔╝██║░░██║                  ║
    ║      ░░░██║░░░██║░░░██║██╔══██╗██╔══██╗██║░░██║                  ║
    ║      ░░░██║░░░╚██████╔╝██║░░██║██║░░██║╚█████╔╝                  ║
    ║      ░░░╚═╝░░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░                  ║
    ║                                                                   ║
    ║                    PROFESSIONAL IP CHANGER                        ║
    ║                         XTREME K1 💀                              ║
    ║                           v3.0                                    ║
    ║                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

print_status() {
    local current_ip="$1"
    local current_loc="$2"
    local network="$3"
    local elapsed="$4"
    local total="$5"
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${WHITE}  PROXY SERVER    ${CYAN}│${GREEN} $PROXY${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${WHITE}  REFRESH RATE    ${CYAN}│${YELLOW} EVERY ${ROTATION_INTERVAL} SECONDS${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${WHITE}  NETWORK         ${CYAN}│${BLUE} $network${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${WHITE}  CURRENT IP      ${CYAN}│${LIME} $current_ip${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${WHITE}  LOCATION        ${CYAN}│${PINK} $current_loc${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${WHITE}  NEXT ROTATION   ${CYAN}│${YELLOW} $(printf "%02d" $((total - elapsed)))s REMAINING${RESET}"
    
    # Progress bar
    local percent=$((elapsed * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    printf "${CYAN}│${WHITE}  PROGRESS        ${CYAN}│${GREEN}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    echo -e "] ${percent}%${RESET}"
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${RESET}"
}

# ==================== MAIN ====================

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--seconds)
            ROTATION_INTERVAL="$2"
            if [[ ! "$ROTATION_INTERVAL" =~ ^[0-9]+$ ]] || [[ $ROTATION_INTERVAL -lt $MIN_INTERVAL ]]; then
                ROTATION_INTERVAL=$DEFAULT_INTERVAL
            fi
            shift 2
            ;;
        -h|--help) show_help ;;
        -v|--version) show_version ;;
        -l|--log) show_log ;;
        -c|--clear) clear_log ;;
        *) shift ;;
    esac
done

# Initialize
check_dependencies
cleanup_processes
create_directories

# Start services
start_tor_instances
sleep 5
start_privoxy
sleep 3

# Get initial info
NETWORK=$(get_network_info)
CURRENT_IP=$(get_current_ip)
CURRENT_LOC=$(get_ip_location)

# Display banner and status
print_banner
print_status "$CURRENT_IP" "$CURRENT_LOC" "$NETWORK" 0 $ROTATION_INTERVAL

# Log initial
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INITIAL - IP: $CURRENT_IP | LOC: $CURRENT_LOC" >> "$LOG_FILE"

# Main rotation loop
COUNTER=1
while true; do
    # Countdown timer
    for ((i=$ROTATION_INTERVAL; i>=0; i--)); do
        clear
        print_banner
        print_status "$CURRENT_IP" "$CURRENT_LOC" "$NETWORK" $((ROTATION_INTERVAL - i)) $ROTATION_INTERVAL
        
        if [[ $i -gt 0 ]]; then
            printf "\r${ORANGE}⏳ Rotating in %2d seconds...${RESET}" $i
        fi
        sleep 1
    done
    
    # Rotate circuits
    printf "\r${YELLOW}🔄 Rotating IP address...${RESET}          "
    rotate_tor_circuits
    sleep 2
    
    # Get new IP
    NEW_IP=$(get_current_ip)
    NEW_LOC=$(get_ip_location)
    
    # Update display with new IP
    clear
    print_banner
    print_status "$NEW_IP" "$NEW_LOC" "$NETWORK" 0 $ROTATION_INTERVAL
    
    # Show rotation complete message
    echo -e "\n${GREEN}✅ Rotation #$COUNTER completed successfully!${RESET}"
    echo -e "${LIME}🌐 New IP Address: $NEW_IP${RESET}"
    echo -e "${PINK}📍 Location: $NEW_LOC${RESET}"
    
    # Log rotation
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ROTATION #$COUNTER - IP: $NEW_IP | LOC: $NEW_LOC" >> "$LOG_FILE"
    
    # Update current variables
    CURRENT_IP="$NEW_IP"
    CURRENT_LOC="$NEW_LOC"
    ((COUNTER++))
    
    sleep 2
done
