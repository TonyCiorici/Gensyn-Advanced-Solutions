#!/bin/bash
set -e

# Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

clear
echo -e "${YELLOW}"
echo "╔══════════════════════════════════════════════╗"
echo "║                                              ║"
echo "║   🚀 HUSTLE AIRDROPS SYSTEM SETUP TOOL       ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "📢 Telegram: ${GREEN}@Hustle_Airdrops${NC}"
echo "=================================================="

# -------------------------------------
# 🧭 Menu for Version Selection
# -------------------------------------
echo -e "${YELLOW}🌀 Hustle Airdrops - Setup Menu${NC}"
echo "=================================================="
echo "1️⃣  Setup with LATEST version"
echo "2️⃣  Setup with DOWNGRADED version (recommended)"
echo "3️⃣  Fix all issues (Dependencies + Known bugs only)"
echo "4️⃣  Backup Credentials only"
echo "=================================================="
read -p "👉 Enter your choice [1/2/3/4]: " version_choice

# -------------------------------------
# 4️⃣ Backup Credentials Only
# -------------------------------------
if [[ "$version_choice" == "4" ]]; then
    echo -e "${YELLOW}📦 Starting Backup Process...${NC}"
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/backup.sh)"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}📝 Open all 3 backup links and save credentials safely.${NC}"
        echo -e "${GREEN}✅ Backup process completed.${NC}"
    else
        echo -e "${RED}❌ Backup script failed to run.${NC}"
    fi
    exit 0
fi

# -------------------------------------
# 3️⃣ Fix All Dependencies & Bugs
# -------------------------------------
if [[ "$version_choice" == "3" ]]; then
    echo -e "${YELLOW}🛠 Running in FIX ALL mode...${NC}"

    sudo apt update && sudo apt install -y \
        python3 python3-venv python3-pip \
        curl wget screen git lsof \
        nodejs ufw yarn

    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt update && sudo apt install -y nodejs

    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
    sudo apt update && sudo apt install -y yarn

    sudo apt install -y ufw
    sudo ufw allow 22
    sudo ufw allow 3000/tcp
    sudo ufw --force enable

    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb || sudo apt --fix-broken install -y

    bash -c "$(curl -fsSL https://raw.githubusercontent.com/hustleairdrops/Gensyn-Advanced-Solutions/main/fixall.sh)"

    echo -e "${GREEN}✅ All issues fixed. You're ready to roll! 🚀${NC}"
    exit 0
fi

# -------------------------------------
# 1️⃣ or 2️⃣ Setup
# -------------------------------------
if [[ "$version_choice" == "1" ]]; then
    echo -e "${YELLOW}🔧 You selected LATEST version.${NC}"
    USE_LATEST=true
elif [[ "$version_choice" == "2" ]]; then
    echo -e "${GREEN}📦 You selected DOWNGRADED version (recommended).${NC}"
    USE_LATEST=false
else
    echo -e "${RED}❌ Invalid choice. Exiting...${NC}"
    exit 1
fi

# -------------------------------------
# 🛠 System Setup
# -------------------------------------
echo -e "${YELLOW}📥 Installing required packages...${NC}"
sudo apt update && sudo apt install -y \
    python3 python3-venv python3-pip \
    curl wget screen git lsof

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update && sudo apt install -y nodejs

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
sudo apt update && sudo apt install -y yarn

sudo apt install -y ufw
sudo ufw allow 22
sudo ufw allow 3000/tcp
sudo ufw --force enable

wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb || sudo apt --fix-broken install -y

echo -e "${GREEN}✅ Basic system setup complete.${NC}"

# -------------------------------------
# 🔁 Prepare for Repository Setup
# -------------------------------------
cd ~ || { echo -e "${RED}❌ Failed to go to home directory${NC}"; exit 1; }

REPO_URL="https://github.com/gensyn-ai/rl-swarm.git"
FOLDER="rl-swarm"
DOWNGRADED_COMMIT="385e0b345aaa7a0a580cbec24aa4dbdb9dbd4642"

BACKUP_DIR="$HOME/swarm_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/swarm_backup_$TIMESTAMP.pem"
SAFE_FILE="$HOME/swarm.pem"

mkdir -p "$BACKUP_DIR"

# -------------------------------------
# 🛡 Backup Existing PEM
# -------------------------------------
if [ -f "$FOLDER/swarm.pem" ]; then
    echo -e "${YELLOW}🔒 Backing up existing swarm.pem...${NC}"
    sudo cp "$FOLDER/swarm.pem" "$SAFE_FILE"
    sudo cp "$FOLDER/swarm.pem" "$BACKUP_FILE"
    sudo chown $(whoami):$(whoami) "$SAFE_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}✅ Backup complete.${NC}"
else
    echo -e "${YELLOW}🆕 No existing PEM found. Skipping backup.${NC}"
fi

# -------------------------------------
# 📦 Clone & Checkout
# -------------------------------------
echo -e "${YELLOW}📁 Cloning RL-Swarm repo...${NC}"
rm -rf "$FOLDER"
git clone "$REPO_URL"
cd "$FOLDER"

if [ "$USE_LATEST" = false ]; then
    echo -e "${YELLOW}⏳ Switching to stable commit...${NC}"
    git checkout "$DOWNGRADED_COMMIT"
fi

# -------------------------------------
# 🔐 Restore PEM
# -------------------------------------
if [ -f "$SAFE_FILE" ]; then
    cp "$SAFE_FILE" swarm.pem
    echo -e "${GREEN}✅ PEM restored.${NC}"
else
    echo -e "${YELLOW}⚠️ No PEM backup found. Continuing setup.${NC}"
fi

# -------------------------------------
# 📦 Install modal-login dependencies (only for downgraded)
# -------------------------------------
if [ "$USE_LATEST" = false ]; then
    echo -e "${YELLOW}📦 Installing modal-login packages...${NC}"
    cd modal-login
    yarn install
    yarn upgrade
    yarn add next@latest viem@latest
    echo -e "${GREEN}✅ modal-login setup complete.${NC}"
    cd ..
fi

# -------------------------------------
# 🛠 Final Fixes
# -------------------------------------
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hustleairdrops/Gensyn-Advanced-Solutions/main/fixall.sh)"

# -------------------------------------
# ✅ Final Message
# -------------------------------------
cd ~
echo
echo -e "${GREEN}🏁 Setup complete! '${FOLDER}' is ready to run.${NC}"
echo -e "🔗 Telegram: ${YELLOW}@Hustle_Airdrops${NC}"
echo -e "📺 Join the community & stay updated!"
echo -e "${YELLOW}🎯 Next time to run: cd rl-swarm && ./run_rl_swarm.sh${NC}"
echo
echo -e "${GREEN}💎 Powered by Hustle Airdrops – Let’s Win Together! 🚀${NC}"
