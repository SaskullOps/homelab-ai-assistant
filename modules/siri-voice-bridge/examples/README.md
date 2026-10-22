# Optional hooks

The bridge works without these. Set `STATUS_URL` / `WAKE_URL` in `.env` only if you install them; otherwise the actions answer "not configured".

Both hooks are tiny systemd socket-activated services that listen **only on the Docker bridge address**, so the n8n container can call them and nothing on your LAN or the internet can. They take no input, so there is nothing to inject into.

| Hook | Folder | Listens on | `.env` value |
|------|--------|------------|--------------|
| Wake-on-LAN | `wake-on-lan/` | `<bridge ip>:8643` | `WAKE_URL=http://<bridge ip>:8643/` |
| Status sentence | `status/` | `<bridge ip>:8644` | `STATUS_URL=http://<bridge ip>:8644/` |

## Install (needs root, Linux with systemd)

```bash
BRIDGE_IP=$(docker network inspect bridge -f '{{(index .IPAM.Config 0).Gateway}}')   # usually 172.17.0.1
MAC=AA:BB:CC:DD:EE:FF                                                             # machine to wake

sudo install -d /usr/local/lib/siri-bridge
sudo install -m 0755 wake-on-lan/wol.py status/status.py /usr/local/lib/siri-bridge/
sudo install -m 0755 wake-on-lan/handler.sh /usr/local/lib/siri-bridge/handler.sh
sudo install -m 0755 status/handler.sh /usr/local/lib/siri-bridge/status-handler.sh

sed "s/@TARGET_MAC@/$MAC/"   wake-on-lan/wake@.service | sudo tee /etc/systemd/system/wake@.service >/dev/null
sed "s/@BRIDGE_IP@/$BRIDGE_IP/" wake-on-lan/wake.socket | sudo tee /etc/systemd/system/wake.socket >/dev/null
sudo cp status/status@.service /etc/systemd/system/
sed "s/@BRIDGE_IP@/$BRIDGE_IP/" status/status.socket | sudo tee /etc/systemd/system/status.socket >/dev/null

sudo systemctl daemon-reload
sudo systemctl enable --now wake.socket status.socket
```

If you use `ufw`, allow the container network to reach those two ports (for example `ufw allow from 172.16.0.0/12 to <bridge ip> port 8643,8644 proto tcp`).

The compose project creates its own network, so the container reaches the host through `host.docker.internal`, which resolves to the default bridge gateway. If that does not work on your host, use the gateway of the compose network instead.

Edit `CHECKS` in `status/status.py` to describe your own services. Wake-on-LAN also needs to be enabled in the target machine's firmware and NIC settings.
