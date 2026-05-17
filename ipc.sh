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
# ═══════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

DEFAULT_INTERVAL=10
MIN_INTERVAL=3
ROTATION_INTERVAL=$DEFAULT_INTERVAL
SCRIPT_DIR="$HOME/turbo"
TOR_DIR="$SCRIPT_DIR/.tor_multi"
PRIVOXY_DIR="$SCRIPT_DIR/.privoxy"
PROXY="127.0.0.1:8118"

while getopts ":s:hv" opt; do
    case $opt in
        s) ROTATION_INTERVAL="$OPTARG" ;;
        h) 
            echo -e "${CYAN}════════════════════════════════════════════${RESET}"
            echo -e "${GREEN}⚡ TURBO IP CHANGER - Help${RESET}"
            echo -e "${CYAN}════════════════════════════════════════════${RESET}"
            echo -e "${YELLOW}Usage:${RESET} turbo ${GREEN}-s <seconds>${RESET}"
            echo -e "  ${GREEN}-s 3-60${RESET}  Set rotation interval"
            echo -e "  ${GREEN}-h${RESET}       Show help"
            echo -e "  ${GREEN}-v${RESET}       Show version"
            echo -e "${CYAN}════════════════════════════════════════════${RESET}"
            exit 0
            ;;
        v)
            echo -e "${GREEN}TURBO v3.0 - XTREME K1 💀${RESET}"
            exit 0
            ;;
    esac
done

# Cleanup
pkill -9 tor 2>/dev/null
pkill -9 privoxy 2>/dev/null
rm -rf "$TOR_DIR" "$PRIVOXY_DIR" 2>/dev/null
mkdir -p "$TOR_DIR" "$PRIVOXY_DIR"

# Start Tor (silent)
TOR_PORTS=(9050 9060 9070 9080 9090)
CONTROL_PORTS=(9051 9061 9071 9081 9091)

for i in ${!TOR_PORTS[@]}; do
    DIR="$TOR_DIR/tor${TOR_PORTS[$i]}"
    mkdir -p "$DIR"
    cat > "$DIR/torrc" 2>/dev/null <<EOF
SocksPort ${TOR_PORTS[$i]}
ControlPort ${CONTROL_PORTS[$i]}
DataDirectory $DIR
CookieAuthentication 0
ExitNodes {us},{ca},{uk},{de},{fr},{nl}
StrictNodes 0
EOF
    tor -f "$DIR/torrc" 2>/dev/null &
done

sleep 6

# Start Privoxy
cat > "$PRIVOXY_DIR/config" 2>/dev/null <<EOF
listen-address 127.0.0.1:8118
toggle 1
buffer-limit 0
forward-socks5t / 127.0.0.1:9050 .
forward-socks5t / 127.0.0.1:9060 .
forward-socks5t / 127.0.0.1:9070 .
forward-socks5t / 127.0.0.1:9080 .
forward-socks5t / 127.0.0.1:9090 .
EOF

privoxy "$PRIVOXY_DIR/config" 2>/dev/null &
sleep 5

# Get real IP function
get_ip() {
    local ip=""
    ip=$(curl -s --proxy http://$PROXY --max-time 6 --connect-timeout 5 "https://api.ipify.org" 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s --proxy http://$PROXY --max-time 5 "https://ifconfig.me/ip" 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s --proxy http://$PROXY --max-time 5 "https://icanhazip.com" 2>/dev/null)
    echo "${ip:-Waiting}"
}

# Get location
get_location() {
    local loc=""
    loc=$(curl -s --proxy http://$PROXY --max-time 5 "http://ip-api.com/json/?fields=city,countryCode" 2>/dev/null | grep -oP '"city":"\K[^"]+' | head -1)
    local country=$(curl -s --proxy http://$PROXY --max-time 5 "http://ip-api.com/json/?fields=countryCode" 2>/dev/null | grep -oP '"countryCode":"\K[^"]+')
    if [[ -n "$loc" && -n "$country" ]]; then
        echo "$loc, $country"
    else
        echo "Unknown"
    fi
}

# Rotate Tor
rotate() {
    for port in ${CONTROL_PORTS[@]}; do
        echo -e "AUTHENTICATE \"\"\r\nSIGNAL NEWNYM\r\nQUIT\r\n" | nc -w 2 127.0.0.1 $port 2>/dev/null
    done
}

# Clear screen and show banner
clear

echo -e "${BLUE}"
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

# Wait for Tor to be ready silently
sleep 8

# Get initial IP
CURRENT_IP=$(get_ip)
CURRENT_LOC=$(get_location)

echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${RESET}"
echo -e "${CYAN}│${WHITE}  PROXY SERVER    ${CYAN}│${GREEN} $PROXY${RESET}"
echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
echo -e "${CYAN}│${WHITE}  REFRESH RATE   ${CYAN}│${YELLOW} EVERY ${ROTATION_INTERVAL} SECONDS${RESET}"
echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
echo -e "${CYAN}│${WHITE}  CURRENT IP     ${CYAN}│${GREEN} $CURRENT_IP${RESET}"
echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${RESET}"
echo -e "${CYAN}│${WHITE}  LOCATION       ${CYAN}│${BLUE} $CURRENT_LOC${RESET}"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${RESET}"
echo -e "${CYAN}─────────────────────────────────────────────────────────────${RESET}"
echo -e "${GREEN}✅ System ready. Starting IP rotation...${RESET}"
echo -e "${CYAN}─────────────────────────────────────────────────────────────${RESET}"

COUNT=1

while true; do
    # Countdown timer
    for ((i=$ROTATION_INTERVAL; i>0; i--)); do
        printf "\r${YELLOW}⏳ Next rotation in: %2d seconds  ${RESET}" $i
        sleep 1
    done
    
    # Rotate silently
    printf "\r${CYAN}🔄 Rotating IP address...                           ${RESET}"
    rotate
    sleep 3
    
    # Get new IP
    NEW_IP=$(get_ip)
    NEW_LOC=$(get_location)
    
    # Clear line and show result
    printf "\r${GREEN}✅ Rotation #%d - New IP: %-15s - %s${RESET}\n" $COUNT "$NEW_IP" "$NEW_LOC"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${RESET}"
    
    ((COUNT++))
done
TURBO_EOF

chmod +x $PREFIX/bin/turbo && echo -e "\033[32m✅ TURBO Updated! Run: turbo -s 5\033[0m"
