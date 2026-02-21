# Letting Other PCs (Kids) Connect to Your Core3 Server

Your server uses these ports (from `MMOCoreORB/bin/conf/config.lua`):

| Service   | Port  |
|----------|-------|
| Login    | 44453 |
| Ping     | 44462 |
| Status   | 44455 |
| ORB      | 44419 |
| Zone(s)  | Dynamic (assigned per zone) |

---

## 1. Priority: Kids on Your Home Network (LAN)

### A. Your dev machine must be reachable

- **If the server runs in WSL (Debian):**  
  WSL2 is behind Windows. Clients on the LAN talk to your **Windows** IP, and Windows forwards to WSL. So you need:
  1. Your **Windows** machine’s LAN IP (e.g. `192.168.1.100`).
  2. **Windows Firewall** allowing inbound TCP (and UDP if the client uses it) for the ports above.

- **Find your Windows IP (from Windows):**
  - `ipconfig` → look at “IPv4 Address” for your active adapter (Wi‑Fi or Ethernet).

### B. Open Windows Firewall for the server

On your dev machine (Windows), run **PowerShell as Administrator** and allow the Core3 ports:

```powershell
# Replace 44453, 44462, 44455, 44419 with your actual ports; add zone ports if documented
New-NetFirewallRule -DisplayName "Core3 Login"   -Direction Inbound -Protocol TCP -LocalPort 44453 -Action Allow
New-NetFirewallRule -DisplayName "Core3 Ping"    -Direction Inbound -Protocol TCP -LocalPort 44462 -Action Allow
New-NetFirewallRule -DisplayName "Core3 Status"  -Direction Inbound -Protocol TCP -LocalPort 44455 -Action Allow
New-NetFirewallRule -DisplayName "Core3 ORB"     -Direction Inbound -Protocol TCP -LocalPort 44419 -Action Allow
```

If your SWG client or server docs say zone ports are in a range (e.g. 44460–44480), add a rule for that range. WSL2 will forward traffic from Windows to the process in WSL as long as you’re binding to `0.0.0.0` (Core3 usually does by default).

### C. Point the kids’ SWG client to your server

On **each kid’s PC** the client must use your dev machine’s IP as the login/server address:

- **If they use a launcher (e.g. SWGEmu launcher, or a custom one):**  
  Set “Login server” or “Server address” to your Windows LAN IP, e.g. `192.168.1.100`. Port is usually `44453` (login).

- **If they edit client files:**  
  There is often a config file (e.g. `swg_client.cfg` or similar in the SWG install folder) or a launcher config that sets the server host. Set that host to your Windows IP. Exact file name depends on the client/launcher you use (SWGEmu, SWG Legends, etc.).

- **No change on the server:**  
  You don’t need to change Core3’s `config.lua` for LAN IP; it’s about where the *client* points.

### D. Quick checklist (kids on LAN)

1. Core3 running in WSL (e.g. `./core3` from `~/localswgserver/MMOCoreORB/bin`).
2. Your Windows LAN IP noted (e.g. `192.168.1.100`).
3. Windows Firewall rules added for Login (44453), Ping (44462), Status (44455), ORB (44419), and any zone ports you use.
4. On kids’ PCs: client/launcher configured with **your Windows IP** and login port **44453**.

---

## 2. Running From a “Shadow Box” (e.g. Shadow PC)

“Shadow box” here means something like **Shadow PC** (remote Windows VM in the cloud).

- **Can you run the server from Shadow?**  
  Yes, in principle: you’d run Core3 (and MySQL, etc.) on the Shadow VM. The catch is **reachability**.

- **The problem:**  
  Shadow PC is on the internet and usually behind NAT. Your kids at home would need to connect to the Shadow VM’s **public IP** and the right **ports** must be open and forwarded to that VM. Many cloud gaming VMs do **not** give you control over inbound port forwarding, so the server might not be reachable from outside.

- **Practical options:**
  1. **Best for “kids at home”:** Run Core3 on your **local dev machine** (as in section 1). Use Shadow only for *playing* (run the SWG client on Shadow and point it to your home server’s **public IP** if you’re not on the same LAN, or use a VPN so Shadow and home are on the same “LAN”).
  2. **Server on Shadow:** Only if Shadow (or your provider) gives you a public IP and port forwarding. Then you’d:
     - Run Core3 on Shadow.
     - Open the same ports (44453, 44462, 44455, 44419, zone ports) in Shadow’s firewall and in the provider’s control panel if needed.
     - Point the kids’ client to Shadow’s **public IP** and port 44453.
  3. **Tunneling (advanced):** Use a tunnel (e.g. Tailscale, ZeroTier, or ngrok) so that either the server or the clients are reachable without manual port forwarding. Then you’d point the client to the tunnel endpoint (e.g. Tailscale IP of the machine running Core3).

So: **first priority = kids on LAN (section 1).** Shadow is doable only if you have control over inbound ports or use a tunnel; otherwise run the server locally and use Shadow only for the client if you want.

---

## 3. Optional: Same network as WSL (localhost)

If a “client” is actually another app or test running **on the same Windows machine** (or in the same WSL instance), use:

- `127.0.0.1` or `localhost` and the same ports (e.g. 44453 for login).

No firewall changes needed for localhost.

---

*Summary: Get your Windows LAN IP, open the Core3 ports in Windows Firewall, and set the kids’ SWG client/launcher to that IP and port 44453. Use Shadow for the server only if you have port forwarding or a tunnel.*
