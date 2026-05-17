pkg update -y && pkg install tor privoxy netcat-openbsd curl jq -y && cat > $PREFIX/bin/turbo << 'TURBO_EOF'
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

# Colors
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

# Default configuration
DEFAULT_INTERVAL=10
MIN_INTERVAL=3
ROTATION_INTERVAL=$DEFAULT_INTERVAL
SCRIPT_DIR="$HOME/turbo"
TOR_DIR="$SCRIPT_DIR/.tor_multi"
PRIVOXY_DIR="$SCRIPT_DIR/.privoxy"
PROXY="127.0.0.1:8118"
LOG_FILE="$SCRIPT_DIR/turbo.log"

# Parse command line arguments
while getopts ":s:hv" opt; do
    case $opt in
        s)
            if [[ "$OPTARG" =~ ^[0-9]+$ ]] && [[ "$OPTARG" -ge $MIN_INTERVAL ]]; then
                ROTATION_INTERVAL="$OPTARG"
            else
                echo -e "${RED}Invalid interval. Using default ${DEFAULT_INTERVAL}s${RESET}"
            fi
            ;;
        h)
            echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
            echo -e "${GREEN}⚡ TURBO IP CHANGER - Help Menu${RESET}"
            echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
            echo -e "${YELLOW}Usage:${RESET} turbo ${GREEN}[OPTIONS]${RESET}"
            echo -e ""
            echo -e "${YELLOW}Options:${RESET}"
            echo -e "  ${GREEN}-s <seconds>${RESET}   Set rotation interval (min: 3s, default: 10s)"
            echo -e "  ${GREEN}-h${RESET}             Show this help message"
            echo -e "  ${GREEN}-v${RESET}             Show version information"
            echo -e ""
            echo -e "${YELLOW}Examples:${RESET}"
            echo -e "  ${CYAN}turbo -s 5${RESET}     Rotate IP every 5 seconds"
            echo -e "  ${CYAN}turbo -s 10${RESET}    Rotate IP every 10 seconds"
            echo -e "  ${CYAN}turbo${RESET}          Run with default settings"
            echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
            exit 0
            ;;
        v)
            echo -e "${GREEN}TURBO IP CHANGER v3.0${RESET}"
            echo -e "${CYAN}Developer: XTREME K1 💀${RESET}"
            echo -e "${YELLOW}Build: 666${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Use -h for help${RESET}"
            exit 1
            ;;
    esac
done

# Function to check dependencies
check_deps() {
    local missing=()
    for cmd in tor privoxy curl nc; do
        if ! command -v $cmd &>/dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Missing: ${missing[*]}${RESET}"
        echo -e "${YELLOW}Run: pkg install ${missing[*]} netcat-openbsd -y${RESET}"
        exit 1
    fi
}

# Function to kill existing processes
cleanup() {
    pkill -9 tor 2>/dev/null
    pkill -9 privoxy 2>/dev/null
    sleep 1
}

# Function to get current IP
get_ip() {
    local ip=""
    ip=$(curl -s --proxy http://$PROXY --max-time 5 --connect-timeout 3 "https://api.ipify.org" 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s --proxy http://$PROXY --max-time 4 "https://ifconfig.me/ip" 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s --proxy http://$PROXY --max-time 4 "https://icanhazip.com" 2>/dev/null)
    echo "${ip:-N/A}"
}

# Function to get location
get_location() {
    local loc=""
    if command -v jq &>/dev/null; then
        loc=$(curl -s --proxy http://$PROXY --max-time 5 "https://ipapi.co/json/" 2>/dev/null | jq -r '"\(.city), \(.country_name)"' 2>/dev/null)
    fi
    [[ -z "$loc" || "$loc" == "null, null" ]] && loc=$(curl -s --proxy http://$PROXY --max-time 4 "http://ip-api.com/json/?fields=city,country" 2>/dev/null | grep -oP '"city":"\K[^"]+' | head -1)
    echo "${loc:-Unknown}"
}

# Function to rotate Tor circuits
rotate_tor() {
    local ports=(9051 9061 9071 9081 9091)
    for port in ${ports[@]}; do
        echo -e "AUTHENTICATE \"\"\r\nSIGNAL NEWNYM\r\nQUIT\r\n" | nc -w 2 127.0.0.1 $port 2>/dev/null
    done
}

# Function to show banner
show_banner() {
    clear
    echo -e "${RED}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                       ║"
    echo "║      ████████╗██╗░░░██╗██████╗░██████╗░░█████╗░                      ║"
    echo "║      ╚══██╔══╝██║░░░██║██╔══██╗██╔══██╗██╔══██╗                      ║"
    echo "║      ░░░██║░░░██║░░░██║██████╔╝██████╔╝██║░░██║                      ║"
    echo "║      ░░░██║░░░██║░░░██║██╔══██╗██╔══██╗██║░░██║                      ║"
    echo "║      ░░░██║░░░╚██████╔╝██║░░██║██║░░██║╚█████╔╝                      ║"
    echo "║      ░░░╚═╝░░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░                      ║"
    echo "║                                                                       ║"
    echo "║                    PROFESSIONAL IP CHANGER                            ║"
    echo "║                         XTREME K1 💀                                  ║"
    echo "║                           v3.0                                        ║"
    echo "║                                                                       ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# Function to show status
show_status() {
    local ip="$1"
    local loc="$2"
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${WHITE}  PROXY SERVER    ${CYAN}│${GREEN} $PROXY${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${WHITE}  REFRESH RATE   ${CYAN}│${YELLOW} EVERY ${ROTATION_INTERVAL} SECONDS${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${WHITE}  CURRENT IP     ${CYAN}│${LIME} $ip${RESET}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${WHITE}  LOCATION       ${CYAN}│${PINK} $loc${RESET}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${RESET}"
}

# Main execution
main() {
    # Check dependencies
    check_deps
    
    # Cleanup old processes
    cleanup
    
    # Create directories
    mkdir -p "$TOR_DIR" "$PRIVOXY_DIR" "$SCRIPT_DIR"
    
    # Tor ports configuration
    TOR_PORTS=(9050 9060 9070 9080 9090)
    CONTROL_PORTS=(9051 9061 9071 9081 9091)
    
    # Start Tor instances
    for i in ${!TOR_PORTS[@]}; do
        local dir="$TOR_DIR/tor${TOR_PORTS[$i]}"
        mkdir -p "$dir"
        cat > "$dir/torrc" << EOF
SocksPort ${TOR_PORTS[$i]}
ControlPort ${CONTROL_PORTS[$i]}
DataDirectory $dir
CookieAuthentication 0
ExitNodes {us},{ca},{uk},{de},{fr},{nl},{ch},{se},{no},{fi}
StrictNodes 0
NumEntryGuards 2
CircuitBuildTimeout 30
LearnCircuitBuildTimeout 0
NewCircuitPeriod 15
EOF
        tor -f "$dir/torrc" 2>/dev/null &
    done
    
    sleep 6
    
    # Start Privoxy
    cat > "$PRIVOXY_DIR/config" << EOF
listen-address 127.0.0.1:8118
toggle 1
enable-remote-toggle 0
enable-remote-http-toggle 0
buffer-limit 0
forward-socks5t / 127.0.0.1:9050 .
forward-socks5t / 127.0.0.1:9060 .
forward-socks5t / 127.0.0.1:9070 .
forward-socks5t / 127.0.0.1:9080 .
forward-socks5t / 127.0.0.1:9090 .
EOF
    
    privoxy "$PRIVOXY_DIR/config" 2>/dev/null &
    sleep 4
    
    # Show banner and initial status
    show_banner
    
    # Get initial IP
    local current_ip=$(get_ip)
    local current_loc=$(get_location)
    show_status "$current_ip" "$current_loc"
    
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${RESET}"
    echo -e "${GREEN}✅ System ready. Starting IP rotation...${RESET}"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${RESET}"
    
    # Log initial
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INITIAL - IP: $current_ip | LOC: $current_loc" >> "$LOG_FILE"
    
    # Main rotation loop
    local counter=1
    
    while true; do
        # Countdown timer
        for ((i=$ROTATION_INTERVAL; i>=0; i--)); do
            printf "\r${YELLOW}⏳ Next rotation in: %2d seconds  ${RESET}" $i
            sleep 1
        done
        
        # Rotate circuits
        printf "\r${CYAN}🔄 Rotating IP address...                           ${RESET}"
        rotate_tor
        sleep 2
        
        # Get new IP
        local new_ip=$(get_ip)
        local new_loc=$(get_location)
        
        # Display result
        printf "\r${GREEN}✅ Rotation #%d - New IP: %-15s - %s${RESET}\n" $counter "$new_ip" "$new_loc"
        echo -e "${CYAN}─────────────────────────────────────────────────────────────${RESET}"
        
        # Log rotation
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ROTATION #$counter - IP: $new_ip | LOC: $new_loc" >> "$LOG_FILE"
        
        ((counter++))
    done
}

# Trap Ctrl+C for clean exit
trap 'echo -e "\n${YELLOW}🛑 Shutting down...${RESET}"; cleanup; echo -e "${GREEN}✅ Clean exit. Goodbye!${RESET}"; exit 0' INT TERM

# Run main function
main
TURBO_EOF
chmod +x $PREFIX/bin/turbo && mkdir -p ~/turbo && echo -e "\033[38;5;208m════════════════════════════════════════════════════════════\033[0m" && echo -e "\033[32m✅ TURBO v3.0 INSTALLED SUCCESSFULLY!\033[0m" && echo -e "\033[36m🚀 Run: turbo -s 5\033[0m" && echo -e "\033[38;5;208m════════════════════════════════════════════════════════════\033[0m"
