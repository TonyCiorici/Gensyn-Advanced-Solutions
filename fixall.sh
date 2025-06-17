#!/bin/bash
set -e

echo "🚀 Hustle Airdrops - Applying All Fixes and Patches"
echo "--------------------------------------------------"

# -------------------------------------
# 1️⃣ Update YAML Training Configs
# -------------------------------------
echo "🛠️ Updating training parameters in grp*.yaml files..."

CONFIG_FOLDER="$HOME/rl-swarm/hivemind_exp/configs/mac"
UPDATED_SETTINGS=(
  "torch_dtype: float32"
  "bf16: false"
  "tf32: false"
  "gradient_checkpointing: false"
  "per_device_train_batch_size: 1"
)

for file in "$CONFIG_FOLDER"/grp*.yaml; do
  echo "📂 Processing: $(basename "$file")"
  for setting in "${UPDATED_SETTINGS[@]}"; do
    key=$(echo "$setting" | cut -d: -f1)
    if grep -q "^$key:" "$file"; then
      sed -i "s|^$key:.*|$setting|" "$file"
    else
      echo "$setting" >> "$file"
    fi
  done
  echo "✅ Updated: $(basename "$file")"
done

# -------------------------------------
# 2️⃣ Replace page.tsx with Latest
# -------------------------------------
echo ""
echo "📥 Downloading latest page.tsx from Hustle GitHub..."

PAGE_DEST="$HOME/rl-swarm/modal-login/app/page.tsx"
curl -fsSL https://raw.githubusercontent.com/hustleairdrops/Gensyn-Advanced-Solutions/main/page.tsx -o "$PAGE_DEST"

if [ $? -eq 0 ]; then
  echo "✅ Successfully updated: page.tsx"
else
  echo "❌ Failed to download page.tsx from GitHub."
fi

# -------------------------------------
# 3️⃣ Apply DHT Peer Fix in grpo_runner.py
# -------------------------------------
echo ""
echo "🔁 Fixing DHT peer bootstrap config in grpo_runner.py..."

perl -i -pe '
  if (/hivemind\.DHT\(start=True, startup_timeout=30/) {
    @matches = /ensure_bootstrap_success=[^,)\s]+/g;
    if (@matches > 1) {
      # Remove duplicates, keep only first
      s/(,?\s*ensure_bootstrap_success=[^,)\s]+)+//g;
      s/(hivemind\.DHT\(start=True, startup_timeout=30, )/$1$matches[0], /;
    } elsif (@matches == 0) {
      # Add if missing
      s/(hivemind\.DHT\(start=True, startup_timeout=30, )/$1ensure_bootstrap_success=False, /;
    }
  }
' "$HOME/rl-swarm/hivemind_exp/runner/grpo_runner.py"

echo "✅ DHT config fix applied."

# -------------------------------------
# ✅ Completion Message
# -------------------------------------
echo ""
echo "🎉 All patches and fixes have been successfully applied!"
echo "💡 Your Hustle Airdrops setup is now ready to roll. Happy hustling! 🚀"
