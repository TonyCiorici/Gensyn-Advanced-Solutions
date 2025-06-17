#!/bin/bash
set -e

echo "🚀 Starting Hustle Airdrops system setup and dependencies installation..."
echo "=================================================="

# -------------------------------------
# 0️⃣ Menu for Version Selection
# -------------------------------------
echo "🌀 Hustle Airdrops - Setup Menu"
echo "=================================================="
echo "1️⃣  Setup with LATEST version"
echo "2️⃣  Setup with DOWNGRADED version (recommended for stability)"
echo "3️⃣  Fix all issues (Dependencies + Known bugs only)"
echo "4️⃣  Backup Credentials only"
echo "=================================================="
read -p "👉 Enter your choice [1/2/3/4]: " version_choice

# -------------------------------------
# 4️⃣ Backup Credentials Only
# -------------------------------------
if [[ "$version_choice" == "4" ]]; then
    echo "📦 Starting Backup Process..."
    [ -f backup.sh ] && rm backup.sh
    curl -sSL -O https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/backup.sh
    chmod +x backup.sh
    ./backup.sh
    echo "📝 After running, open all 3 links one by one and save your credentials safely."
    echo "✅ Backup process completed."
    exit 0
fi

# -------------------------------------
# 3️⃣ Fix All Mode - Dependencies + Bugs
# -------------------------------------
if [[ "$version_choice" == "3" ]]; then
    echo "🛠️ Running in FIX ALL mode (dependencies + fixes only)..."

    sudo apt update && sudo apt install -y \
        python3 python3-venv python3-pip \
        curl wget screen git lsof \
        nodejs ufw yarn

    # Node 20.x
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt update && sudo apt install -y nodejs

    # Yarn
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
    sudo apt update && sudo apt install -y yarn

    # Firewall
    sudo apt install -y ufw
    sudo ufw allow 22
    sudo ufw allow 3000/tcp
    sudo ufw --force enable

    # Cloudflared
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb || sudo apt --fix-broken install -y

    # Fix script
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/hustleairdrops/Gensyn-Advanced-Solutions/main/fixall.sh)"

    echo "✅ All issues fixed. You're ready to roll 🚀"
    exit 0
fi

# -------------------------------------
# 1️⃣ or 2️⃣ Setup Modes
# -------------------------------------
if [[ "$version_choice" == "1" ]]; then
    echo "🔧 You selected LATEST version."
    USE_LATEST=true
elif [[ "$version_choice" == "2" ]]; then
    echo "📦 You selected DOWNGRADED version (recommended for stability)."
    USE_LATEST=false
else
    echo "❌ Invalid choice. Exiting."
    exit 1
fi

# -------------------------------------
# 1. Update System and Install Basic Packages
# -------------------------------------
sudo apt update && sudo apt install -y \
    python3 python3-venv python3-pip \
    curl wget screen git lsof

# -------------------------------------
# 2. Install Node.js 20.x
# -------------------------------------
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt update && sudo apt install -y nodejs

# -------------------------------------
# 3. Install Yarn Package Manager
# -------------------------------------
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list > /dev/null
sudo apt update && sudo apt install -y yarn

# -------------------------------------
# 4. Setup UFW Firewall
# -------------------------------------
sudo apt install -y ufw
sudo ufw allow 22
sudo ufw allow 3000/tcp
sudo ufw --force enable

# -------------------------------------
# 5. Install Latest cloudflared
# -------------------------------------
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb || sudo apt --fix-broken install -y

echo "✅ System setup complete!"

# -------------------------------------
# 6. Prepare for Repository Setup
# -------------------------------------
cd ~ || { echo "❌ Failed to go to home directory"; exit 1; }

REPO_URL="https://github.com/gensyn-ai/rl-swarm.git"
FOLDER="rl-swarm"
DOWNGRADED_COMMIT="385e0b345aaa7a0a580cbec24aa4dbdb9dbd4642"

BACKUP_DIR="$HOME/swarm_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/swarm_backup_$TIMESTAMP.pem"
SAFE_FILE="$HOME/swarm.pem"

mkdir -p "$BACKUP_DIR"

# -------------------------------------
# 7. Backup Existing swarm.pem (if present)
# -------------------------------------
if [ -f "$FOLDER/swarm.pem" ]; then
    echo "🔒 Old user detected. Backing up existing swarm.pem..."
    sudo cp "$FOLDER/swarm.pem" "$SAFE_FILE"
    sudo cp "$FOLDER/swarm.pem" "$BACKUP_FILE"
    sudo chown $(whoami):$(whoami) "$SAFE_FILE" "$BACKUP_FILE"
    echo "✅ swarm.pem backed up successfully."
else
    echo "🆕 New user detected or no existing swarm.pem. Skipping backup."
fi

# -------------------------------------
# 8. Clone Repository
# -------------------------------------
echo "🧹 Cleaning old $FOLDER and cloning fresh..."
rm -rf "$FOLDER"
git clone "$REPO_URL"
cd "$FOLDER"

if [ "$USE_LATEST" = false ]; then
    echo "⏳ Checking out downgraded commit..."
    git checkout "$DOWNGRADED_COMMIT"
fi

# -------------------------------------
# 9. Restore swarm.pem (if backup exists)
# -------------------------------------
if [ -f "$SAFE_FILE" ]; then
    cp "$SAFE_FILE" swarm.pem
    echo "✅ swarm.pem restored successfully."
else
    echo "⚠️ No swarm.pem backup found to restore."
fi

# -------------------------------------
# 10. Install modal-login Dependencies
# -------------------------------------
echo "📦 Installing modal-login dependencies..."
cd modal-login
yarn install
yarn upgrade
yarn add next@latest viem@latest
echo "✅ modal-login setup complete."

# -------------------------------------
# 11. Apply Additional Fixes (if any)
# -------------------------------------
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hustleairdrops/Gensyn-Advanced-Solutions/main/fixall.sh)"

# -------------------------------------
# 12. Final Cleanup and Completion Message
# -------------------------------------
cd ~
echo "🏁 Setup complete! '$FOLDER' is ready to use 🚀"
echo "🎯 Powered by Hustle Airdrops – Let’s Win Together!"
