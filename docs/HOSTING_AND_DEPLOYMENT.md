# 🖥️ Foreverbot — Architecture, Hosting & 24/7 Deployment Guide

This guide explains how **World of Warcraft: Forever Companion** runs once installed, how it connects securely to Discord, and how you can run it 24/7 on your own hardware or on a cloud server.

---

## ⚡ 1. How Does the Bot Run? (Under the Hood)

When you run `./start_bot.sh` (or `start_bot.bat` on Windows):

1. **Local Execution on Your Hardware:**
   Foreverbot runs as a lightweight standard Python process on your own machine.
   - **RAM Footprint:** ~114 MB steady (no memory leaks).
   - **CPU Footprint:** ~0% when idle; sub-second micro-spikes (< 10 ms) only when answering a player's query.
   - **Storage:** Pre-bundled SQLite catalog (`wow_forever.db`, ~8.6 MB). All 20,872 items, quests, NPCs, and drop rates live on your disk.

2. **How Discord Communicates with Your Computer:**
   ```
      [Player in Discord Server]
                 │
                 │  Types /item Thunderfury
                 ▼
          [Discord Servers]
                 │
                 │  (Pushes slash command over persistent outbound WebSocket)
                 ▼
      [Your Machine (PC / Mac / Server)]
       ├── bot.py receives interaction event
       ├── Queries local wow_forever.db in < 1 ms
       └── Responds back to Discord with formatted embed
   ```

3. **Security & Privacy (Zero Exposed Ports):**
   - **No Port Forwarding:** You do **not** need to open any ports on your home router or firewall.
   - **Outbound Only:** When the bot launches, it makes an *outbound* encrypted WebSocket connection to Discord's Gateway (`wss://gateway.discord.gg`).
   - **IP Protection:** Discord acts as an isolating proxy between players and your bot. Discord users and guild members **never** see your IP address or home network.

---

## 💤 2. Sleep & Shutdown Behavior

* **When your computer is ON and awake:** Foreverbot is connected and online in Discord with full sub-second response times.
* **When your computer SLEEPS or TURNS OFF:** The WebSocket connection closes. Discord marks the bot as **Offline**. If a player types a slash command while the bot is offline, Discord responds: *"The application did not respond"*.
* **When your computer WAKES UP:** Running `./start_bot.sh` reconnects the bot in ~2 seconds. All guild commands and server permissions resume immediately with no reconfiguration needed.

---

## 🚀 3. How to Keep Foreverbot Running 24/7

Depending on your preference, here are the most popular ways to host Foreverbot 24/7:

### Option A: On a Home PC, Mac Mini, or Raspberry Pi (Free)
Because Foreverbot only requires ~114 MB of RAM, it easily runs in the background of any computer, old laptop, or a $35 Raspberry Pi.

#### Auto-Start on Linux Boot (`systemd` Service)
If you are running Ubuntu, Debian, Fedora, Arch, or Raspberry Pi OS, configure `systemd` to start the bot automatically on boot and restart it if it ever stops:

1. Create a systemd service file:
   ```bash
   sudo nano /etc/systemd/system/foreverbot.service
   ```

2. Paste the following configuration (adjust `User` and `WorkingDirectory` to match your path):
   ```ini
   [Unit]
   Description=World of Warcraft: Forever Discord Bot
   After=network.target

   [Service]
   Type=simple
   User=s1l3nt
   WorkingDirectory=/home/s1l3nt/wow-forever-bot
   ExecStart=/home/s1l3nt/wow-forever-bot/.venv/bin/python3 bot.py
   Restart=always
   RestartSec=10
   Environment=PYTHONUNBUFFERED=1

   [Install]
   WantedBy=multi-user.target
   ```

3. Enable and start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now foreverbot.service
   ```

4. Check live status:
   ```bash
   sudo systemctl status foreverbot.service
   # View live logs:
   journalctl -u foreverbot.service -f
   ```

---

### Option B: Free Cloud Hosting (Oracle Cloud Always-Free Tier)
Oracle Cloud provides an **"Always Free"** tier with up to 4 ARM Ampere cores and 24 GB of RAM at **$0 / month forever**.
1. Create a free account at [Oracle Cloud](https://www.oracle.com/cloud/free/).
2. Create an Ubuntu VM instance.
3. SSH into your instance, install Python:
   ```bash
   sudo apt update && sudo apt install -y python3 python3-venv git
   ```
4. Clone or upload your bot folder:
   ```bash
   git clone https://github.com/ForeverbotDev/foreverbot.git
   cd foreverbot
   cp .env.example .env
   nano .env # Paste your DISCORD_BOT_TOKEN
   chmod +x start_bot.sh
   ./start_bot.sh
   ```
5. Set up `systemd` (as described in Option A) so it runs permanently in the cloud.

---

### Option C: Budget Cloud VPS ($3 - $5 / month)
If you prefer a 1-click cloud server without managing home hardware:
* **Hetzner Cloud:** ~€3.50/month (high performance, European & US data centers).
* **DigitalOcean:** $4/month Basic Droplet.
* **Linode / Akamai:** $5/month Nanode.

Deploying on any Linux VPS takes under 3 minutes using the standard Linux install steps in `README.md`.

---

### Option D: Docker & Docker Compose
If you run Unraid, TrueNAS, Synology, or use Docker on a VPS:

1. Ensure `.env` is configured with your `DISCORD_BOT_TOKEN`.
2. Launch using Docker Compose:
   ```bash
   docker compose up -d
   ```
3. Check container logs:
   ```bash
   docker compose logs -f
   ```

---

## 📊 Summary Comparison

| Hosting Method | Monthly Cost | Hardware Requirements | Best For |
| :--- | :---: | :--- | :--- |
| **Personal PC / Laptop** | **$0** | Your existing daily computer | Prototyping, small friend guilds, testing |
| **Raspberry Pi / Home Server** | **$0** | Raspberry Pi 3/4/5 or spare PC | 24/7 home hosting with zero noise & low power |
| **Oracle Cloud Always-Free** | **$0** | Free Cloud VM | 24/7 cloud hosting with zero ongoing cost |
| **Budget VPS (Hetzner / DO)** | **$3–$5** | 1 vCPU / 1GB RAM Droplet | Guild leaders wanting high-availability cloud hosting |
| **Docker Container** | **Variable** | Any Docker-compatible host | Homelab enthusiasts, Unraid, TrueNAS |
