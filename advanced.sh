#!/bin/bash

# Enable debug mode for tracing (remove in production)
# set -x

# ----------------------------------------
# Styling
# ----------------------------------------
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

# ----------------------------------------
# Paths
# ----------------------------------------
SWARM_DIR="$HOME/rl-swarm"
TEMP_DATA_PATH="$SWARM_DIR/modal-login/temp-data"
HOME_DIR="$HOME"
AUTO_INPUT_FILE="$HOME/.swarm_auto_inputs"
LOG_FILE="$HOME/swarm_log.txt"
NODE_PID_FILE="$HOME/.node_pid"  

# ----------------------------------------
# Global Variables
# ----------------------------------------
BACKGROUND_PID=0
STOP_REQUESTED=0
NODE_PID=0

# ----------------------------------------
# Logging Function
# ----------------------------------------
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    # Only display ERROR or WARN in terminal
    case "$level" in
        ERROR) echo -e "${RED}$message${NC}" ;;
        WARN) echo -e "${YELLOW}$message${NC}" ;;
    esac
}

# Initialize log file
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$NODE_PID_FILE")"
touch "$LOG_FILE" "$NODE_PID_FILE"
log_message "INFO" "Starting GENSYN RL-SWARM LAUNCHER at $(date)"

# Change to home directory
cd "$HOME" || { log_message "ERROR" "Could not access $HOME. Exiting."; exit 1; }

# ----------------------------------------
# Default Config
# ----------------------------------------
create_default_config() {
    log_message "INFO" "Creating default config at $AUTO_INPUT_FILE"
    cat <<EOF > "$AUTO_INPUT_FILE"
Y
A
7
N

EOF
    chmod 600 "$AUTO_INPUT_FILE"
    [ $? -eq 0 ] && log_message "INFO" "Default config created" || log_message "ERROR" "Failed to create default config"
}

if [ ! -f "$AUTO_INPUT_FILE" ]; then
    create_default_config
fi

# ----------------------------------------
# Install and Validate Environment
# ----------------------------------------
validate_environment() {
    log_message "INFO" "Validating and installing environment dependencies"
    local missing_deps=()

    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        missing_deps+=("python3")
    fi

    if ! python3 -m venv --help >/dev/null 2>&1; then
        missing_deps+=("python3-venv")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_message "INFO" "Installing missing dependencies: ${missing_deps[*]}"
        sudo apt update >/dev/null 2>&1
        sudo apt install -y "${missing_deps[@]}" >/dev/null 2>&1
        [ $? -eq 0 ] && log_message "INFO" "Installed dependencies: ${missing_deps[*]}" || { log_message "ERROR" "Failed to install dependencies: ${missing_deps[*]}. Exiting."; exit 1; }
    fi

    log_message "INFO" "Environment validated: git, python3, and venv available"
}

# ----------------------------------------
# Backup Function (to HOME, only if needed)
# ----------------------------------------
backup_files() {
    log_message "INFO" "Checking for backup to $HOME_DIR"
    mkdir -p "$TEMP_DATA_PATH" "$HOME_DIR"
    chmod 700 "$TEMP_DATA_PATH" "$HOME_DIR"
    [ $? -eq 0 ] || log_message "ERROR" "Failed to set permissions on $TEMP_DATA_PATH or $HOME_DIR"

    local copied=0
    for src in "$SWARM_DIR/swarm.pem" "$TEMP_DATA_PATH/userData.json" "$TEMP_DATA_PATH/userApiKey.json"; do
        dest="$HOME_DIR/$(basename "$src")"
        if [ -f "$src" ] && [ ! -f "$dest" ]; then
            if cp -f "$src" "$dest" 2>/dev/null; then
                chmod 600 "$dest"
                log_message "INFO" "Backed up $(basename "$src") to $HOME_DIR"
                ((copied++))
            else
                log_message "ERROR" "Failed to back up $(basename "$src") to $HOME_DIR"
            fi
        fi
    done

    [ $copied -gt 0 ] && log_message "INFO" "Backed up $copied file(s)"
}

# ----------------------------------------
# Restore Function (from HOME)
# ----------------------------------------
restore_files() {
    log_message "INFO" "Restoring files to $SWARM_DIR"
    mkdir -p "$TEMP_DATA_PATH"
    chmod 700 "$TEMP_DATA_PATH"
    [ $? -eq 0 ] || log_message "ERROR" "Failed to create $TEMP_DATA_PATH"

    local restored=0
    for src in "$HOME_DIR/swarm.pem" "$HOME_DIR/userData.json" "$HOME_DIR/userApiKey.json"; do
        if [ -f "$src" ]; then
            dest="$SWARM_DIR/$(basename "$src")"
            if [[ "$(basename "$src")" == "userData.json" || "$(basename "$src")" == "userApiKey.json" ]]; then
                dest="$TEMP_DATA_PATH/$(basename "$src")"
            fi
            if [ ! -f "$dest" ]; then
                if cp -f "$src" "$dest" 2>/dev/null; then
                    chmod 600 "$dest"
                    log_message "INFO" "Restored $(basename "$src") to $dest"
                    ((restored++))
                else
                    log_message "ERROR" "Failed to restore $(basename "$src") to $dest"
                fi
            else
                log_message "INFO" "$(basename "$src") already exists in $dest, skipping restore"
            fi
        fi
    done

    [ $restored -gt 0 ] && log_message "INFO" "Restored $restored file(s)"
}

# ----------------------------------------
# Clone Repository
# ----------------------------------------
clone_repository() {
    log_message "INFO" "Cloning rl-swarm to $SWARM_DIR"
    rm -rf "$SWARM_DIR" 2>/dev/null
    git clone https://github.com/gensyn-ai/rl-swarm.git "$SWARM_DIR" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_message "INFO" "Repository cloned successfully"
        chmod -R 700 "$SWARM_DIR"
    else
        log_message "ERROR" "Failed to clone rl-swarm repository. Exiting."
        exit 1
    fi
}

# ----------------------------------------
# Python Environment Setup
# ----------------------------------------
setup_python_env() {
    log_message "INFO" "Setting up Python environment in $SWARM_DIR"
    cd "$SWARM_DIR" || { log_message "ERROR" "Could not access $SWARM_DIR. Exiting."; exit 1; }
    if [ ! -d ".venv" ]; then
        python3 -m venv .venv 2>/dev/null
        [ $? -eq 0 ] && log_message "INFO" "Created virtual environment" || { log_message "ERROR" "Failed to create virtual environment"; exit 1; }
    fi
    source .venv/bin/activate
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt >/dev/null 2>&1
        [ $? -eq 0 ] && log_message "INFO" "Installed Python dependencies" || log_message "WARN" "Failed to install dependencies"
    fi
    log_message "INFO" "Python environment activated"
}

# ----------------------------------------
# Launch Function
# ----------------------------------------
launch_rl_swarm() {
    log_message "INFO" "Checking for run_rl_swarm.sh"
    if [ ! -f "$SWARM_DIR/run_rl_swarm.sh" ]; then
        log_message "ERROR" "run_rl_swarm.sh not found in $SWARM_DIR. Exiting."
        exit 1
    fi
    chmod +x "$SWARM_DIR/run_rl_swarm.sh"
    if [ -f "$AUTO_INPUT_FILE" ]; then
        IFS=$'\n' read -r testnet swarm param push hf_token < "$AUTO_INPUT_FILE"
        log_message "INFO" "Launching rl-swarm with config: Testnet=$testnet, Swarm=$swarm, Param=$param, Push=$push"
        cd "$SWARM_DIR" || { log_message "ERROR" "Could not access $SWARM_DIR. Exiting."; exit 1; }
        source .venv/bin/activate
        ./run_rl_swarm.sh <<EOF
$testnet
$swarm
$param
$push
$hf_token
EOF
        local exit_code=$?
        backup_files
        return $exit_code
    else
        log_message "INFO" "Launching rl-swarm with manual input"
        cd "$SWARM_DIR" || { log_message "ERROR" "Could not access $SWARM_DIR. Exiting."; exit 1; }
        source .venv/bin/activate
        ./run_rl_swarm.sh
        local exit_code=$?
        backup_files
        return $exit_code
    fi
}

# ----------------------------------------
# Auto-Fix Function
# ----------------------------------------
auto_fix() {
    log_message "INFO" "Running auto-fix checks"
    if [ ! -d "$SWARM_DIR" ]; then
        log_message "WARN" "$SWARM_DIR missing. Cloning repository."
        clone_repository
    fi
    if [ ! -f "$SWARM_DIR/run_rl_swarm.sh" ]; then
        log_message "WARN" "run_rl_swarm.sh missing. Re-cloning repository."
        clone_repository
    fi
    if [ ! -d "$SWARM_DIR/.venv" ] || [ ! -f "$SWARM_DIR/.venv/bin/activate" ]; then
        log_message "WARN" "Python environment missing or broken. Re-creating."
        rm -rf "$SWARM_DIR/.venv"
        setup_python_env
    fi
    restore_files
    log_message "INFO" "Auto-fix completed"
}

# ----------------------------------------
# Menu Option 1: Auto-restart with existing files
# ----------------------------------------
option_1() {
    log_message "INFO" "Selected Option 1: Auto-restart with existing files"
    auto_fix
    setup_python_env
    backup_files
    while [ $STOP_REQUESTED -eq 0 ]; do
        log_message "INFO" "Starting rl-swarm"
        restore_files
        launch_rl_swarm
        local exit_code=$?
        log_message "WARN" "rl-swarm exited with code $exit_code. Restarting in 1 second..."
        auto_fix
        setup_python_env
        sleep 1
    done
}

# ----------------------------------------
# Menu Option 2: Run once with existing files
# ----------------------------------------
option_2() {
    log_message "INFO" "Selected Option 2: Run once with existing files"
    auto_fix
    setup_python_env
    backup_files
    restore_files
    log_message "INFO" "Starting rl-swarm (no auto-restart)"
    launch_rl_swarm
}

# ----------------------------------------
# Menu Option 3: Delete and start fresh
# ----------------------------------------
option_3() {
    log_message "INFO" "Selected Option 3: Delete and start fresh"
    log_message "WARN" "Deleting old rl-swarm directory"
    rm -rf "$SWARM_DIR"
    clone_repository
    setup_python_env
    log_message "INFO" "Starting fresh rl-swarm"
    launch_rl_swarm
}

# ----------------------------------------
# Menu Option 4: Update configuration
# ----------------------------------------
option_4() {
    log_message "INFO" "Selected Option 4: Update configuration"
    echo -e "${CYAN}⚙️ Updating configuration...${NC}"
    read -p "${YELLOW}➡️ Connect to Testnet? (Y/n) [Y]: ${NC}" testnet
    testnet=${testnet:-Y}
    read -p "${YELLOW}➡️ Swarm type? (A=Math, B=Math Hard) [A]: ${NC}" swarm
    swarm=${swarm:-A}
    read -p "${YELLOW}➡️ Parameter count (0.5, 1.5, 7, 32, 72) [7]: ${NC}" param
    param=${param:-7}
    read -p "${YELLOW}➡️ Push to Hugging Face Hub? (y/N) [N]: ${NC}" push
    push=${push:-N}
    hf_token=""
    [[ "$push" =~ [Yy] ]] && read -p "${YELLOW}🔑 Enter HuggingFace token: ${NC}" hf_token
    cat <<EOF > "$AUTO_INPUT_FILE"
$testnet
$swarm
$param
$push
$hf_token
EOF
    chmod 600 "$AUTO_INPUT_FILE"
    [ $? -eq 0 ] && log_message "INFO" "Configuration saved to $AUTO_INPUT_FILE" || log_message "ERROR" "Failed to save configuration"
    echo -e "${GREEN}✅ Config saved!${NC}"
    exit 0
}

# ----------------------------------------
# Menu Option 5: Fix All Errors
# ----------------------------------------
option_5() {
    log_message "INFO" "Selected Option 5: Fixing all errors"
    echo -e "${CYAN}🛠️ Fixing BF16 / Login / DHTNode Bootstrap Error / Minor Errors...${NC}"
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/hustleairdrops/Gensyn_Guide_with_all_solutions/main/solutions_file/fixall.sh)" >/dev/null 2>&1
    [ $? -eq 0 ] && echo -e "${GREEN}✅ Errors fixed successfully!${NC}" || echo -e "${RED}❌ Error fixing failed. Check logs.${NC}"
    log_message "INFO" "Error fixing completed"
}

# ----------------------------------------
# Display Logo
# ----------------------------------------
display_logo() {
    echo -e "${CYAN}"
    echo -e " ██╗░░██╗██╗░░░██╗░██████╗████████╗██╗░░░░░███████╗  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░░██████╗ "
    echo -e " ██║░░██║██║░░░██║██╔════╝╚══██╔══╝██║░░░░░██╔════╝  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝ "
    echo -e " ███████║██║░░░██║╚█████╗░░░░██║░░░██║░░░░░█████╗░░  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝╚█████╗░ "
    echo -e " ██╔══██║██║░░░██║░╚═══██╗░░░██║░░░██║░░░░░██╔══╝░░  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░░╚═══██╗ "
    echo -e " ██║░░██║╚██████╔╝██████╔╝░░░██║░░░███████╗███████╗  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░██████╔╝ "
    echo -e " ╚═╝░░╚═╝░╚═════╝░╚═════╝░░░░╚═╝░░░╚══════╝╚══════╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚═════╝░ "
    echo -e "${YELLOW}        Gensyn Node Guide By Hustle Airdrops"
    echo -e "        https://github.com/HustleAirdrops"
    echo -e "${NC}"
}

# ----------------------------------------
# Stop Command Handler (Ctrl+X)
# ----------------------------------------
stop_script() {
    log_message "INFO" "Ctrl+X detected. Stopping script..."
    STOP_REQUESTED=1
    if [ $BACKGROUND_PID -ne 0 ]; then
        kill $BACKGROUND_PID 2>/dev/null
        log_message "INFO" "Terminated background backup process (PID: $BACKGROUND_PID)"
    fi
    if [ $NODE_PID -ne 0 ]; then
        kill $NODE_PID 2>/dev/null
        log_message "INFO" "Terminated node process (PID: $NODE_PID)"
    fi
    echo -e "${GREEN}✅ Script and node stopped gracefully.${NC}"
    exit 0
}

# Configure Ctrl+X (ASCII 24) using stty
stty intr ^X
trap stop_script INT

# ----------------------------------------
# Show Smart Menu
# ----------------------------------------
while true; do
    clear
    display_logo
    echo -e "${BOLD}${CYAN}\n🧠 GENSYN RL-SWARM LAUNCHER${NC}\n"
    log_message "INFO" "Displaying main menu"

    validate_environment

    if [ -f "$HOME_DIR/swarm.pem" ] || [ -f "$HOME_DIR/userData.json" ] || [ -f "$HOME_DIR/userApiKey.json" ] || [ -d "$SWARM_DIR" ]; then
        echo -e "${BOLD}${YELLOW}⚠️ Existing setup detected. Choose an option:${NC}"
        echo -e "  ${BOLD}1️⃣ Run with existing files (Auto-restart on crash)${NC}"
        echo -e "  ${BOLD}2️⃣ Run normally with existing files${NC}"
        echo -e "  ${BOLD}3️⃣ Delete and start fresh${NC}"
        echo -e "  ${BOLD}4️⃣ Update configuration${NC}"
        echo -e "  ${BOLD}5️⃣ Fix all errors (BF16/Login/DHTNode/Minor)${NC}"
        echo -e "${CYAN}ℹ️ Press Ctrl+X to stop the script at any time.${NC}"
    else
        log_message "INFO" "No existing setup found. Starting fresh"
        echo -e "${GREEN}✅ No existing setup found. Starting fresh...${NC}"
        clone_repository
        setup_python_env
        launch_rl_swarm
        exit 0
    fi

    # Handle Menu Selection
    read -p $'\e[1m➡️ Enter your choice (1-5): \e[0m' choice
    case "$choice" in
        1) option_1; break ;;
        2) option_2; break ;;
        3) option_3; break ;;
        4) option_4; break ;;
        5) option_5; break ;;
        *) log_message "ERROR" "Invalid choice: $choice"; echo -e "${RED}❌ Invalid choice. Try again.${NC}" ;;
    esac
done

# ----------------------------------------
# Live Auto Backup (background, quiet)
# ----------------------------------------
(
    while true; do
        sleep 300
        backup_files
        log_message "INFO" "Completed auto-backup cycle"
    done
) &
BACKGROUND_PID=$!
log_message "INFO" "Started background backup process (PID: $BACKGROUND_PID)"
