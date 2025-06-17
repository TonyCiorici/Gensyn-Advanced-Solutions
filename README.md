# 🚀 Gensyn RL-Swarm Node Setup Guide + All Solutions

Easily set up and run your Gensyn RL-Swarm node on **Linux/WSL**.  
All commands are copy-paste ready!

---

> **Want a more advanced setup?**  
> [Click here for the Advanced Guide](./Advanced.md)  
> - No need to login again and again when restarting  
> - No need to add inputs like Y, A, 7, N  
> - Auto-restart if terminated  
> - Almost all issues fixed  
> - Try this for a smoother experience!

---

## 🌀 Quick Start

**No need to manually clone any installation files!**  
Just run the following command in your terminal to launch the interactive setup menu:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/HustleAirdrops/Gensyn-Advanced-Solutions/main/installation.sh)
```

You'll see a menu like this:

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

Choose the option that fits your needs and follow the prompts.

---

## 🌐 Login Instructions

### Local PC

- A web pop-up will appear automatically.
- If not, open [http://localhost:3000/](http://localhost:3000/) in your browser.
- Login with your email, enter the OTP, and return to your terminal.

### VPS

1. Open a **new terminal/tab** and run:
    ```bash
    cloudflared tunnel --url http://localhost:3000
    ```
2. Open the provided link in your browser, login, then return to the node terminal.

---

## 🔄 Next Day Start

To restart your node the next day:

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

## 🏆 Check Rewards

- Visit [@GensynReward_bot](https://t.me/GensynReward_bot) on Telegram.
- Send `/add` and then your **Peer ID** for updates.

---

## ⚠️ Note

If you see  
`0x0000000000000000000000000000000000000000`  
in the **Connected EOA Address** section, your contribution is **not** being recorded.

- Delete the existing `swarm.pem` file.
- Start again with a new email.

---

## 💬 Need Help?

- Reach out: [@Legend_Aashish](https://t.me/Legend_Aashish)
- 📺 All guides, videos & updates: [@Hustle_Airdrops](https://t.me/Hustle_Airdrops)
- 🚀 Stay ahead — join the channel now!

--- 
