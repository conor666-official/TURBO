# ⚡ TURBO IP-CHANGER (Termux) — XTREME K1 💀

> Termux-friendly IP rotation tool using Tor + Privoxy.

---

## About

- Rotates your public IP via Tor.
- Provides a local HTTP proxy at `127.0.0.1:8118`.
- Shows new IP and location in terminal.
- Configurable refresh interval (`-s` option, min 5s, default 10s).

---

## Requirements

```bash
pkg update -y && pkg upgrade -y
pkg install tor privoxy curl netcat-openbsd jq -y

```
```
git clone https://github.com/conor666-official/IP-CHANGER-TERMUX.git ~/IP-CHANGER-TERMUX \
&& mkdir -p ~/ipc \
&& cp ~/IP-CHANGER-TERMUX/ipc.sh ~/ipc/ipc.sh \
&& chmod +x ~/ipc/ipc.sh \
&& echo -e '#!/data/data/com.termux/files/usr/bin/bash\nexec /data/data/com.termux/files/home/ipc/ipc.sh "$@"' > $PREFIX/bin/ipc \
&& chmod +x $PREFIX/bin/ipc \
&& echo "Installed! Run: ipc -s 5"
