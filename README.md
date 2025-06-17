<div align="center">

# 🌀 Gensyn Node Setup Guide

</div>

Welcome! This guide will help you set up your Gensyn node step by step. There are **two main setup methods**: a **Simple Setup** for beginners and an **Advanced Setup** for experienced users. The final section covers login, rewards, troubleshooting, and support.

---

## 📦 Overview

- **Simple Setup:** Fastest way to get started, minimal manual steps.
- **Advanced Setup:** More control, automation, and troubleshooting options.
- **Extras:** Login help, rewards, and support resources.

---

## 1️⃣ Simple Setup (Beginner Friendly)

### 🚀 Quick Start

No need to manually download or clone files!  
Just run this command in your terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/HustleAirdrops/Gensyn-Advanced-Solutions/main/installation.sh)
```

### 📝 What Happens Next?

You’ll see an interactive menu:

```
🌀 Hustle Airdrops - Setup Menu
=======================================
1️⃣  Setup with LATEST version  
2️⃣  Setup with DOWNGRADED version (recommended for stability)  
3️⃣  Fix all issues (Dependencies + Known bugs only)  
4️⃣  Backup Credentials only  
=======================================
👉 Enter your choice [1/2/3/4]:
```

- **Option 1:** Latest version (for new features)
- **Option 2:** Downgraded version (**recommended for stability**)
- **Option 3:** Fix common issues
- **Option 4:** Backup your credentials

**Follow the prompts as per your choice.**

### 🔄 Restarting Your Node

To restart your node later, use:

```bash
cd rl-swarm
```
```bash
python3 -m venv .venv
source .venv/bin/activate
```
```bash
./run_rl_swarm.sh
```

---

## 2️⃣ Advanced Setup (For Power Users)

### 💡 Why Use Advanced?

- **No repeated logins** — stay connected
- **No manual inputs** — fully automated
- **Auto-restart** — node restarts if it crashes
- **Self-healing** — fixes most issues automatically

### ⚡ One-Line Setup

Run this command for advanced options:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/HustleAirdrops/Gensyn-Advanced-Solutions/main/advanced.sh)
```

### 🛠️ Advanced Menu Options

```
1️⃣ Auto-Restart Mode - Run with existing files, restarts on crash
2️⃣ Single Run - Run once with existing files
3️⃣ Fresh Start - Delete everything and start anew
4️⃣ Update Config - Change Config
5️⃣ Fix Errors - Resolve BF16/Login/DHTNode issues
6️⃣ Backup files
```

- **Auto-Restart Mode:** Recommended for most users (runs 24/7)
- **Single Run:** For one-time execution
- **Fresh Start:** Clean slate if you face issues
- **Update Config:** Change settings without reinstalling
- **Fix Errors:** Troubleshoot common problems
- **Backup:** Secure your credentials

---

## 3️⃣ Login, Rewards & Support

### 🌐 Login Instructions

#### On Local PC

- A browser window should open automatically.
- If not, visit [http://localhost:3000/](http://localhost:3000/) manually.
- Login with your email, enter the OTP, and return to your terminal.

#### On VPS/Server

- In a new terminal/tab, run:
    ```bash
    cloudflared tunnel --url http://localhost:3000
    ```
- Open the provided link in your browser, login, and return to the node terminal.

---

### 🔐 Backup Credentials
```bash
[ -f backup.sh ] && rm backup.sh; curl -sSL -O https://raw.githubusercontent.com/zunxbt/gensyn-testnet/main/backup.sh && chmod +x backup.sh && ./backup.sh
```

### 🏆 Checking Rewards

- Go to [@GensynReward_bot](https://t.me/GensynReward_bot) on Telegram.
- Send `/add` and your Peer ID to track rewards.

**Important:**  
If you see `0x0000000000000000000000000000000000000000` as your EOA address, your work is **not** being recorded.

- Delete the `swarm.pem` file.
- Restart setup with a new email.

---

### 💬 Need Help?

- **Direct Support:** [@Legend_Aashish](https://t.me/Legend_Aashish)
- **Guides & Updates:** [@Hustle_Airdrops](https://t.me/Hustle_Airdrops)
- **Stay updated — join the channel!**

---

## ❓ FAQ & Troubleshooting

For frequently asked questions and troubleshooting steps, **please refer to our detailed guide:**  
👉 [Gensyn FAQ & Troubleshooting Guide](./gensyn-faq-troubleshooting.md)

---

## ✅ Summary

- **Simple Setup:** Fast, minimal steps — best for most users.
- **Advanced Setup:** More control, automation, and troubleshooting.
- **Check rewards and get support if needed.**

**Choose the method that fits your comfort level. Follow the steps, and your Gensyn node will be running smoothly!** 
