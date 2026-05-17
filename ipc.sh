#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# ⚡ CATCH ME IF YOU CAN ⚡
# IP-Changer by XTREME K1 💀
# Professional Edition v2.0
# ==========================================

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"

# Default values
DEFAULT_INTERVAL=10
MIN_INTERVAL=5
ROTATION_INTERVAL=$DEFAULT_INTERVAL
SCRIPT_DIR="$HOME/ipc"
TOR_DIR="$SCRIPT_DIR/.tor_multi"
PRIVOXY_DIR="$SCRIPT_DIR/.privoxy"
PROXY="127.0.0.1:8118"
LOG_FILE="$SCRIPT_DIR/ipc.log"

# Create script directory if not exists
mkdir -p "$SCRIPT_DIR"

# Parse arguments
while getopts ":s:h" opt; do
    case $opt in
        s)
            if [[ "$OPTARG" =~ ^[0-9]+$ ]] && [[ "$OPTARG" -ge $MIN_INTERVAL ]]; then
                ROTATION_INTERVAL="$OPTARG"
            else
                echo -e "${RED}Invalid interval. Using default ${DEFAULT_INTERVAL}s.${RESET}"
            fi
            ;;
        h)
            echo -e "${CYAN}════════════════════════════════════════════${RESET}"
            echo -e "${GREEN}⚡ IPC - IP Changer by XTREME K1 💀${RESET}"
            echo -e "${CYAN}════════════════════════════════════════════${RESET}"
            echo -e "${YELLOW}Usage:${RESET} ipc [-s seconds]"
            echo -e ""
            echo -e "${YELLOW}Options:${RESET}"
            echo -e "  ${GREEN}-s seconds${RESET}   Set refresh interval (min: ${MIN_INTERVAL}s, default: ${DEFAULT_INTERVAL}s)"
            echo -e "  ${GREEN}-h${RESET}           Show this help message"
            echo -e ""
            echo -e "${YELLOW}Examples:${RESET}"
            echo -e "  ${CYAN}ipc -s 10${RESET}      Change IP every 10 seconds"
            echo -e "  ${CYAN}ipc -s 5${RESET}       Aggressive mode (min interval)"
            echo -e "  ${CYAN}ipc${RESET}            Run with default settings"
            echo -e "${CYAN}════════════════════════════════════════════${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Use -h for help.${RESET}"
            exit 1
            ;;
    esac
done

# Check dependencies
check_dependencies() {
    local missing=()
    
    for cmd in tor privoxy curl nc; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[!] Missing dependencies: ${missing[*]}${RESET}"
        echo -e "${YELLOW}[*] Install with: pkg install ${missing[*]} -y${RESET}"
        exit 1
    fi
}

# Cleanup previous instances
cleanup() {
    echo -e "${YELLOW}[*] Cleaning up previous instances...${RESET}"
    pkill -f "tor" 2>/dev/null
    pkill -f "privoxy" 2>/dev/null
    sleep 2
    rm -rf "$TOR_DIR" "$PRIVOXY_DIR"
}

# Get network interface
get_network_info() {
    local net=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K\S+' | head -1)
    if [[ -z "$net" ]]; then
        net=$(ip link show | grep -oP '^[0-9]+: \K\w+' | grep -v lo | head -1)
    fi
    echo "${net:-Unknown}"
}

# Get IP and location with fallback methods
get_ip_location() {
    local result=""
    local ip=""
    local location=""
    
    # Method 1: Using ipapi.co with jq (if available)
    if command -v jq &> /dev/null; then
        result=$(curl -s --proxy http://$PROXY --max-time 5 "https://ipapi.co/json/" 2>/dev/null)
        if [[ -n "$result" ]] && [[ "$result" != *"error"* ]]; then
            ip=$(echo "$result" | jq -r '.ip // "Unknown"')
            local city=$(echo "$result" | jq -r '.city // "Unknown"')
            local region=$(echo "$result" | jq -r '.region // "Unknown"')
            local country=$(echo "$result" | jq -r '.country_name // "Unknown"')
            location="${city}, ${region}, ${country}"
            [[ "$location" == "Unknown, Unknown, Unknown" ]] && location="Unknown"
            echo "$ip - $location"
            return 0
        fi
    fi
    
    # Method 2: Using ifconfig.me (simple IP only)
    ip=$(curl -s --proxy http://$PROXY --max-time 5 "https://ifconfig.me/ip" 2>/dev/null | tr -d '\n')
    if [[ -n "$ip" ]] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip - Location Unknown"
        return 0
    fi
    
    # Method 3: Using icanhazip.com
    ip=$(curl -s --proxy http://$PROXY --max-time 5 "https://icanhazip.com" 2>/dev/null | tr -d '\n')
    if [[ -n "$ip" ]] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip - Location Unknown"
        return 0
    fi
    
    echo "Failed to get IP - Check proxy connection"
    return 1
}

# Rotate Tor circuits
rotate_tor() {
    local success=0
    for ctrl_port in ${CONTROL_PORTS[@]}; do
        if echo -e "AUTHENTICATE \"\"\r\nSIGNAL NEWNYM\r\nQUIT\r\n" | nc -w 2 127.0.0.1 $ctrl_port 2>/dev/null | grep -q "250"; then
            ((success++))
        fi
    done
    echo $success
}

# Spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 $pid 2>/dev/null; do
        for ((i=0; i<${#spinstr}; i++)); do
            printf "\r${CYAN}[*] ${spinstr:$i:1} Rotating Tor circuits...${RESET}"
            sleep $delay
        done
    done
    printf "\r"
}

# Main execution
main() {
    # Initial checks
    check_dependencies
    
    # Cleanup old instances
    cleanup
    
    # Create directories
    mkdir -p "$TOR_DIR" "$PRIVOXY_DIR"
    
    # Tor ports configuration
    TOR_PORTS=(9050 9060 9070 9080 9090)
    CONTROL_PORTS=(9051 9061 9071 9081 9091)
    
    # Start Tor instances
    echo -e "${YELLOW}[*] Starting Tor instances...${RESET}"
    local tor_count=0
    for i in ${!TOR_PORTS[@]}; do
        local DIR="$TOR_DIR/tor$i"
        mkdir -p "$DIR"
        cat > "$DIR/torrc" <<EOF
SocksPort ${TOR_PORTS[$i]}
ControlPort ${CONTROL_PORTS[$i]}
DataDirectory $DIR
CookieAuthentication 0
ExitNodes {us},{ca},{uk},{de},{fr}
StrictNodes 0
EOF
        tor -f "$DIR/torrc" 2>/dev/null &
        if [[ $? -eq 0 ]]; then
            ((tor_count++))
        fi
    done
    
    echo -e "${GREEN}[+] Started $tor_count Tor instances${RESET}"
    sleep 5
    
    # Start Privoxy
    echo -e "${YELLOW}[*] Starting Privoxy...${RESET}"
    cat > "$PRIVOXY_DIR/config" <<EOF
listen-address 127.0.0.1:8118
toggle 1
enable-remote-toggle 0
enable-remote-http-toggle 0
buffer-limit 4096
forward-socks5t / 127.0.0.1:9050 .
EOF
    # Add fallback Tor ports
    for port in ${TOR_PORTS[@]:1}; do
        echo "forward-socks5t / 127.0.0.1:$port ." >> "$PRIVOXY_DIR/config"
    done
    
    privoxy "$PRIVOXY_DIR/config" 2>/dev/null &
    sleep 3
    
    # Display header
    clear
    echo -e "${CYAN}⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣶⣶⠖⠀⠀⠲⣶⣶⣤⡀${RESET}"
    echo -e "${CYAN}⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⡿⠋⠀⠀⠀⠀⠀⠀⠙⢿⣿⣦⡀${RESET}"
    echo -e "${CYAN}⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣷⡀${RESET}"
    echo -e "${CYAN}⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣷${RESET}"
    echo -e "${CYAN}⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣇⣤⠶⠛⣛⣉⣙⡛⠛⢶⣄⣸⣿⣿⣿${RESET}"
    echo -e "${CYAN}⠀⠀⠀⠀⠀⢀⣀⣿⣿⣿⡟⢁⣴⣿⣿⣿⣿⣿⣿⣦⡈⢿⣿⣿⣿⣀⡀${RESET}"
    echo -e "${CYAN}⠀⢠⣴⣿⣿⣿⣿⡟⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡌⢿⣿⣿⣿⣿⣦⡄${RESET}"
    echo -e "${CYAN}⣴⣿⣿⡿⠿⢛⣻⡇⢸⡟⠻⣿⣿⣿⣿⣿⡿⠟⢻⡇⣸⣛⡛⠿⣿⣿⣿⣦${RESET}"
    echo -e "${CYAN}⢸⣿⡿⠋⠀⠀⢸⣿⣿⡜⢧⣄⣀⣉⡿⣿⣉⣀⣠⣼⢁⣿⣿⡇⠀⠀⠙⢿⣿⡆${RESET}"
    echo -e "${CYAN}⣿⣿⠁⠀⠀⠀⠈⣿⣿⡇⣿⡿⠛⣿⣵⣮⣿⡟⢻⡿⢨⣿⣿⠀⠀⠀⠀⠈⣿⣿${RESET}"
    echo -e "${CYAN}⢿⡟⠀⠀⠀⠀⠀⠘⣿⣷⣤⣄⡀⣿⣿⣿⣿⢁⣤⣶⣿⣿⠃⠀⠀⠀⠀⠀⣿⡟${RESET}"
    echo -e "${CYAN}⠘⠇⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⡇⢿⣿⣿⣿⢸⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠻⠃${RESET}"
    echo -e ""
    echo -e "${MAGENTA}════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}    ⚡ CATCH ME IF YOU CAN ⚡${RESET}"
    echo -e "${MAGENTA}════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}    IP-Changer by XTREME K1 💀${RESET}"
    echo -e "${CYAN}────────────────────────────────────────────${RESET}"
    echo -e "${YELLOW} Proxy Server :${RESET} $PROXY"
    echo -e "${YELLOW} Refresh Rate :${RESET} ${ROTATION_INTERVAL}s"
    echo -e "${YELLOW} Network      :${RESET} $(get_network_info)"
    echo -e "${YELLOW} Tor Instances:${RESET} $tor_count"
    echo -e "${CYAN}────────────────────────────────────────────${RESET}"
    
    # Test proxy connection
    echo -e "${YELLOW}[*] Testing proxy connection...${RESET}"
    local test_ip=$(curl -s --proxy http://$PROXY --max-time 10 "https://ifconfig.me/ip" 2>/dev/null)
    if [[ -n "$test_ip" ]]; then
        echo -e "${GREEN}[+] Proxy is working! Current IP: $test_ip${RESET}"
    else
        echo -e "${RED}[!] Proxy not responding. Check Tor and Privoxy.${RESET}"
    fi
    echo -e "${CYAN}────────────────────────────────────────────${RESET}"
    
    # Main rotation loop
    local rotation_count=0
    while true; do
        ((rotation_count++))
        
        # Rotate Tor circuits with animation
        echo -e "${YELLOW}[*] Rotation #$rotation_count - Renewing Tor circuits...${RESET}"
        
        local rotated=$(rotate_tor)
        sleep 2  # Wait for circuits to establish
        
        # Get new IP with location
        local new_ip=$(get_ip_location)
        
        echo -e "${GREEN}✅ NEW IP : $new_ip${RESET}"
        echo -e "${MAGENTA}💀 MADE BY XTREME K1${RESET}"
        echo -e "${CYAN}────────────────────────────────────────────${RESET}"
        
        # Log to file
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rotation #$rotation_count - $new_ip" >> "$LOG_FILE"
        
        # Countdown with visual feedback
        for ((i=$ROTATION_INTERVAL; i>0; i--)); do
            printf "\r${BLUE}🔄 Next refresh in ${i}s ${RESET}"
            sleep 1
        done
        printf "\r${GREEN}🔄 Refreshing...                         ${RESET}\n"
    done
}

# Trap Ctrl+C for clean exit
trap 'echo -e "\n${YELLOW}[*] Shutting down...${RESET}"; cleanup; echo -e "${GREEN}[+] Clean exit. Goodbye!${RESET}"; exit 0' INT TERM

# Run main function
main
