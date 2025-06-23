#!/bin/bash
# set -e

# Check if terminal supports colors
if [ -t 1 ] && [ -n "$(tput colors)" ] && [ "$(tput colors)" -ge 8 ]; then
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    CYAN=$(tput setaf 6)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    NC=$(tput sgr0)
else
    BOLD=""
    RED=""
    GREEN=""
    YELLOW=""
    CYAN=""
    BLUE=""
    MAGENTA=""
    NC=""
fi

# Paths
SWARM_DIR="$HOME/rl-swarm"
CONFIG_FILE="$SWARM_DIR/.swarm_config"
LOG_FILE="$HOME/swarm_log.txt"
SWAP_FILE="/swapfile"
DOWNGRADED_COMMIT="385e0b345aaa7a0a580cbec24aa4dbdb9dbd4642"

# Global Variables
REPO_URL="https://github.com/gensyn-ai/rl-swarm.git"
KEEP_TEMP_DATA=true

# Logging
log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"
    case "$level" in
        ERROR) echo -e "${RED}$msg${NC}" ;;
        WARN) echo -e "${YELLOW}$msg${NC}" ;;
        INFO) echo -e "${CYAN}$msg${NC}" ;;
    esac
}

# Initialize
init() {
    clear
    touch "$LOG_FILE"
    log "INFO" "=== HUSTLE AIRDROPS RL-SWARM MANAGER STARTED ==="
}

# Display Header
show_header() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐"
    echo "│  ██╗░░██╗██╗░░░██╗░██████╗████████╗██╗░░░░░███████╗  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░░██████╗  │"
    echo "│  ██║░░██║██║░░░██║██╔════╝╚══██╔══╝██║░░░░░██╔════╝  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝  │"
    echo "│  ███████║██║░░░██║╚█████╗░░░░██║░░░██║░░░░░█████╗░░  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝╚█████╗░  │"
    echo "│  ██╔══██║██║░░░██║░╚═══██╗░░░██║░░░██║░░░░░██╔══╝░░  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░░╚═══██╗  │"
    echo "│  ██║░░██║╚██████╔╝██████╔╝░░░██║░░░███████╗███████╗  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░██████╔╝  │"
    echo "│  ╚═╝░░╚═╝░╚═════╝░╚═════╝░░░░╚═╝░░░╚══════╝╚══════╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚═════╝░  │"
    echo "└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘"
    echo -e "${YELLOW}           🚀 Gensyn RL-Swarm Launcher by Hustle Airdrops 🚀${NC}"
    echo -e "${YELLOW}              GitHub: https://github.com/HustleAirdrops${NC}"
    echo -e "${YELLOW}              Telegram: https://t.me/Hustle_Airdrops${NC}"
    echo -e "${GREEN}===============================================================================${NC}"
}

# Dependencies
install_deps() {
    sudo apt update >/dev/null 2>&1
    sudo apt install -y \
        python3 python3-venv python3-pip \
        curl wget screen git lsof \
        nodejs ufw yarn jq perl >/dev/null 2>&1
    
    # Node.js
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >/dev/null 2>&1
    sudo apt install -y nodejs >/dev/null 2>&1
    
    # Yarn
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - >/dev/null 2>&1
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null
    sudo apt update >/dev/null 2>&1
    sudo apt install -y yarn >/dev/null 2>&1
    
    # Firewall
    sudo ufw allow 22 >/dev/null 2>&1
    sudo ufw allow 3000/tcp >/dev/null 2>&1
    echo "y" | sudo ufw enable >/dev/null 2>&1
    
    # Cloudflared
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb >/dev/null 2>&1 || sudo apt --fix-broken install -y >/dev/null 2>&1
    rm -f cloudflared-linux-amd64.deb >/dev/null 2>&1
}

# Swap Management
manage_swap() {
    if [ ! -f "$SWAP_FILE" ]; then
        sudo fallocate -l 1G "$SWAP_FILE" >/dev/null 2>&1
        sudo chmod 600 "$SWAP_FILE" >/dev/null 2>&1
        sudo mkswap "$SWAP_FILE" >/dev/null 2>&1
        sudo swapon "$SWAP_FILE" >/dev/null 2>&1
        echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null 2>&1
    fi
}

disable_swap() {
    if [ -f "$SWAP_FILE" ]; then
        sudo swapoff "$SWAP_FILE"
        sudo rm -f "$SWAP_FILE"
        sudo sed -i "\|$SWAP_FILE|d" /etc/fstab
    fi
}


# Fixall Script
run_fixall() {
    echo -e "${CYAN}🔧 Applying comprehensive fixes...${NC}"
    if curl -fsSL https://raw.githubusercontent.com/hustleairdrops/Gensyn-Advanced-Solutions/main/fixall.sh | bash >/dev/null 2>&1; then
        touch "$SWARM_DIR/.fixall_done"
        echo -e "${GREEN}✅ All fixes applied successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to apply fixes!${NC}"
    fi
    sleep 5
}

# Modify run script
modify_run_script() {
    local run_script="$SWARM_DIR/run_rl_swarm.sh"

    if [ -f "$run_script" ]; then
        # 1. Preserve shebang line and remove old KEEP_TEMP_DATA definition
        awk '
        NR==1 && $0 ~ /^#!\/bin\/bash/ { print; next }
        $0 !~ /^\s*: "\$\{KEEP_TEMP_DATA:=.*\}"/ { print }
        ' "$run_script" > "$run_script.tmp" && mv "$run_script.tmp" "$run_script"

        # 2. Inject new KEEP_TEMP_DATA just after #!/bin/bash
        sed -i '1a : "${KEEP_TEMP_DATA:='"$KEEP_TEMP_DATA"'}"' "$run_script"

        # 3. Patch rm logic only if not already patched
        if grep -q 'rm -r \$ROOT_DIR/modal-login/temp-data/\*\.json' "$run_script" && \
           ! grep -q 'if \[ "\$KEEP_TEMP_DATA" != "true" \]; then' "$run_script"; then

            perl -i -pe '
                s#rm -r \$ROOT_DIR/modal-login/temp-data/\*\.json 2> /dev/null \|\| true#
if [ "\$KEEP_TEMP_DATA" != "true" ]; then
    rm -r \$ROOT_DIR/modal-login/temp-data/*.json 2> /dev/null || true
fi#' "$run_script"
        fi
    fi
}

fix_kill_command() {
    local run_script="$SWARM_DIR/run_rl_swarm.sh"

    if [ -f "$run_script" ]; then
        if grep -q 'kill -- -\$\$ || true' "$run_script"; then
            perl -i -pe 's#kill -- -\$\$ \|\| true#kill -TERM -- -\$\$ 2>/dev/null || true#' "$run_script"
            log "INFO" "✅ Fixed kill command in $run_script to suppress errors"
        else
            log "INFO" "ℹ️ Kill command already updated or not found"
        fi
    else
        log "ERROR" "❌ run_rl_swarm.sh not found at $run_script"
    fi
}

# Clone Repository
clone_repo() {
    local version="$1"
    sudo rm -rf "$SWARM_DIR" 2>/dev/null
    git clone "$REPO_URL" "$SWARM_DIR" >/dev/null 2>&1
    cd "$SWARM_DIR"
    
    if [ "$version" == "downgraded" ]; then
        git checkout "$DOWNGRADED_COMMIT" >/dev/null 2>&1
        cd modal-login
        yarn install >/dev/null 2>&1
        yarn upgrade >/dev/null 2>&1
        yarn add next@latest viem@latest >/dev/null 2>&1
        cd ..
    fi
}


create_default_config() {
    log "INFO" "Creating default config at $CONFIG_FILE"
    mkdir -p "$SWARM_DIR"
    cat <<EOF > "$CONFIG_FILE"
TESTNET=Y
SWARM=A
PARAM=7
PUSH=N
EOF
    chmod 600 "$CONFIG_FILE"
    log "INFO" "Default config created"
}

fix_swarm_pem_permissions() {
    local pem_file="$SWARM_DIR/swarm.pem"
    if [ -f "$pem_file" ]; then
        sudo chown "$(whoami)":"$(whoami)" "$pem_file"
        sudo chmod 600 "$pem_file"
        log "INFO" "✅ swarm.pem permissions fixed"
    else
        log "WARN" "⚠️ swarm.pem not found at $pem_file"
    fi
}


# Install Node
install_node() {
    set +m  

    show_header
    echo -e "${CYAN}${BOLD}INSTALLATION MENU${NC}"
    echo "1. Latest version"
    echo "2. Downgraded version (recommended)"
    echo -e "${YELLOW}===============================================================================${NC}"
    
    read -p "${BOLD}${YELLOW}➡️ Choose version [1-2]: ${NC}" version_choice
    [[ ! "$version_choice" =~ ^[1-2]$ ]] && {
        echo -e "${RED}❌ Invalid version choice!${NC}"
        return 1
    }

    local version=$([ "$version_choice" == "1" ] && echo "latest" || echo "downgraded")

    echo -e "\n${CYAN}Auto-login configuration:${NC}"
    echo "Preserve login data between sessions? (recommended for auto-login)"
    read -p "${BOLD}Enable auto-login? [Y/n]: ${NC}" auto_login

    KEEP_TEMP_DATA=$([[ "$auto_login" =~ ^[Nn]$ ]] && echo "false" || echo "true")
    export KEEP_TEMP_DATA

    # Handle swarm.pem from SWARM_DIR
    if [ -f "$SWARM_DIR/swarm.pem" ]; then
        echo -e "\n${YELLOW}⚠️ Existing swarm.pem detected in SWARM_DIR!${NC}"
        echo "1. Keep and use existing Swarm.pem"
        echo "2. Delete and generate new Swarm.pem"
        echo "3. Cancel installation"
        read -p "${BOLD}➡️ Choose action [1-3]: ${NC}" pem_choice

        case $pem_choice in
            1)
                sudo cp "$SWARM_DIR/swarm.pem" "$HOME/swarm.pem"
                log "INFO" "PEM copied from SWARM_DIR to HOME"
                ;;
            2)
                sudo rm -rf "$HOME/swarm.pem"
                log "INFO" "Old PEM deleted from SWARM_DIR"
                ;;
            3)
                echo -e "${RED}❌ Installation cancelled by user.${NC}"
                sleep 1
                return
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Continuing with existing PEM.${NC}"
                ;;
        esac
    fi

    echo -e "\n${YELLOW}Starting installation...${NC}"

    spinner() {
        local pid=$1
        local msg="$2"
        local spinstr="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        while kill -0 "$pid" 2>/dev/null; do
            for (( i=0; i<${#spinstr}; i++ )); do
                printf "\r$msg ${spinstr:$i:1} "
                sleep 0.15
            done
        done
        printf "\r$msg ✅ Done"; tput el; echo
    }

    ( install_deps ) & spinner $! "📦 Installing dependencies"
    ( clone_repo "$version" ) & spinner $! "📥 Cloning $version repo"
    ( modify_run_script ) & spinner $! "🧠 Modifying run script"
    ( run_fixall ) & spinner $! "🛠 Applying final fixes"

    if [ -f "$HOME/swarm.pem" ]; then
        sudo cp "$HOME/swarm.pem" "$SWARM_DIR/swarm.pem"
        sudo chmod 600 "$SWARM_DIR/swarm.pem"
    fi

    echo -e "\n${GREEN}✅ Installation completed!${NC}"
    echo -e "Auto-login: ${GREEN}$([ "$KEEP_TEMP_DATA" == "true" ] && echo "ENABLED" || echo "DISABLED")${NC}"
    echo -e "${YELLOW}${BOLD}👉 Press Enter to return to the menu...${NC}"
    read
    sleep 1
}

# Run Node
run_node() {
    show_header
    echo -e "${CYAN}${BOLD}🚀 RUN MODE SELECTION${NC}"
    echo "1. 🔄  Auto-Restart Mode (🟢 Recommended)"
    echo "2. 🎯  Single Run (Normally Run)"
    echo "3. 🧼  Fresh Start (Reinstall + Run)"
    echo -e "${YELLOW}===============================================================================${NC}"
    
    read -p "${BOLD}${YELLOW}➡️ Choose run mode [1-3]: ${NC}" run_choice
    
    if [ ! -f "$SWARM_DIR/swarm.pem" ]; then
        if [ -f "$HOME/swarm.pem" ]; then
            sudo cp "$HOME/swarm.pem" "$SWARM_DIR/swarm.pem"
            sudo chmod 600 "$SWARM_DIR/swarm.pem"
        else
            echo "Error: swarm.pem not found in HOME directory."
            exit 1
        fi
    fi
    
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "\n${BOLD}${CYAN}⚙️  CURRENT CONFIGURATION${NC}"
        echo -e "${YELLOW}-------------------------------------------------${NC}"
        echo -e "🔗 Testnet        : ${GREEN}$TESTNET${NC}"
        echo -e "🧠 Swarm Type     : ${GREEN}$SWARM${NC}"
        echo -e "📏 Parameter Size : ${GREEN}$PARAM${NC}"
        echo -e "🚀 Push to HF     : ${GREEN}$PUSH${NC}"
        echo -e "${YELLOW}-------------------------------------------------${NC}"
    else
        echo -e "${RED}❗ No config found. Please update configuration first.${NC}"
        update_config
        source "$CONFIG_FILE"
    fi
    
    # Ensure KEEP_TEMP_DATA is set
    : "${KEEP_TEMP_DATA:=true}"
    export KEEP_TEMP_DATA
    modify_run_script
    sudo chmod +x "$SWARM_DIR/run_rl_swarm.sh"
    fix_kill_command
    
    case $run_choice in
        1)
            log "INFO" "Starting node in auto-restart mode"
            cd "$SWARM_DIR"
            fix_swarm_pem_permissions
            manage_swap
            python3 -m venv .venv
            source .venv/bin/activate
            while true; do
                KEEP_TEMP_DATA="$KEEP_TEMP_DATA" ./run_rl_swarm.sh <<EOF
$TESTNET
$SWARM
$PARAM
$PUSH
EOF
                log "WARN" "Node crashed, restarting in 5 seconds..."
                echo -e "${YELLOW}⚠️ Node crashed. Restarting in 5 seconds...${NC}"
                sleep 5
            done
            ;;
        2)
            log "INFO" "Starting node in single-run mode"
            cd "$SWARM_DIR"
            fix_swarm_pem_permissions
            manage_swap
            python3 -m venv .venv
            source .venv/bin/activate
            KEEP_TEMP_DATA="$KEEP_TEMP_DATA" ./run_rl_swarm.sh <<EOF
$TESTNET
$SWARM
$PARAM
$PUSH
EOF
            ;;
        3)
            log "INFO" "Starting fresh installation + run"
            install_node && run_node
            ;;
        *)
            echo -e "${RED}❌ Invalid choice!${NC}"
            ;;
    esac
}

# Update Configuration
update_config() {
    show_header
    echo -e "${BOLD}${CYAN}⚙️  CURRENT CONFIGURATION${NC}"

    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "${YELLOW}-------------------------------------------------${NC}"
        echo -e "🔗 Testnet        : ${GREEN}$TESTNET${NC}"
        echo -e "🧠 Swarm Type     : ${GREEN}$SWARM${NC}"
        echo -e "📏 Parameter Size : ${GREEN}$PARAM${NC}"
        echo -e "🚀 Push to HF     : ${GREEN}$PUSH${NC}"
        echo -e "${YELLOW}-------------------------------------------------${NC}"
    else
        echo -e "${RED}❗ No config found. Creating default...${NC}"
        create_default_config
    fi

    echo -e "\n${BOLD}${MAGENTA}✏️  ENTER NEW VALUES (Press Enter to keep current):${NC}"

    read -p "🧠 Swarm Type [A/B]: " new_swarm
    read -p "📏 Parameter Size [0.5, 1.5, 7, 32, 72]: " new_param

    SWARM=${new_swarm:-$SWARM}
    PARAM=${new_param:-$PARAM}

    cat <<EOF > "$CONFIG_FILE"
TESTNET=Y
SWARM=$SWARM
PARAM=$PARAM
PUSH=N
EOF

    echo -e "\n${GREEN}✅ Configuration updated successfully!${NC}"
    echo -e "${YELLOW}-------------------------------------------------${NC}"
    cat "$CONFIG_FILE"
    echo -e "${YELLOW}-------------------------------------------------${NC}"
    sleep 5
}

# Reset Peer ID
reset_peer() {
    echo -e "${RED}${BOLD}⚠️ WARNING: This will delete ALL node keys and data!${NC}"
    read -p "${BOLD}Are you sure? [y/N]: ${NC}" confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo rm -f ~/swarm.pem ~/userData.json ~/userApiKey.json
        sudo rm -f "$SWARM_DIR"/{swarm.pem,modal-login/temp-data/{userData.json,userApiKey.json}}
        echo -e "${GREEN}✅ All keys and data deleted!${NC}"
        echo -e "${YELLOW}⚠️ Reinstall node to generate new keys${NC}"
    else
        echo -e "${YELLOW}⚠️ Operation canceled${NC}"
    fi
    sleep 5
}

# Main Menu
main_menu() {
    while true; do
        show_header
        echo -e "${BOLD}${MAGENTA}==================== 🧠 GENSYN MAIN MENU ====================${NC}"
        echo "1. 🛠  Install/Reinstall Node"
        echo "2. 🚀 Run Node"
        echo "3. ⚙️  Update Configuration"
        echo "4. 🔧 Fix All Errors"
        echo "5. ♻️  Reset Peer ID"
        echo "6. 🗑️  Delete Everything & Start New"
        echo "7. ❌ Exit"
        echo -e "${GREEN}===============================================================================${NC}"
        
        read -p "${BOLD}${YELLOW}➡️ Select option [1-7]: ${NC}" choice
        
        case $choice in
            1) install_node ;;
            2) run_node ;;
            3) update_config ;;
            4) run_fixall ;;
            5) reset_peer ;;
            6)
                echo -e "\n${RED}${BOLD}⚠️ WARNING: This will delete ALL node data!${NC}"
                read -p "${BOLD}Are you sure you want to continue? [y/N]: ${NC}" confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    sudo rm -rf "$SWARM_DIR"
                    sudo rm -f ~/swarm.pem ~/userData.json ~/userApiKey.json
                    echo -e "${GREEN}✅ All node data deleted!${NC}"

                    echo -e "\n${YELLOW}➕ Do you want to reinstall the node now?${NC}"
                    read -p "${BOLD}Proceed with fresh install? [Y/n]: ${NC}" reinstall_choice
                    if [[ ! "$reinstall_choice" =~ ^[Nn]$ ]]; then
                        install_node
                    else
                        echo -e "${CYAN}❗ Fresh install skipped.${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️ Operation canceled${NC}"
                fi
                ;;
            7)
                echo -e "\n${GREEN}✅ Exiting... Thank you for using Hustle Manager!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Initialize and start
init
trap "echo -e '\n${GREEN}✅ Stopped gracefully${NC}'; disable_swap; return" SIGINT
main_menu
