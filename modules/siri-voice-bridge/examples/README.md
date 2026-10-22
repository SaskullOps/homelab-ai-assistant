# Optional hooks

The bridge works without these. Set `STATUS_URL` / `WAKE_URL` in `.env` only if you install them; otherwise the actions answer "not configured".

Both hooks are tiny systemd socket-activated services that listen **only on the Docker bridge address**, not on the LAN interface. In practice that means:

- The hooks are **unauthenticated**. Anything that can open a TCP connection to `<bridge ip>:8643` or `:8644` can trigger them: any local process on the host, and any container attached to the default bridge network. Nothing on the LAN or the internet can reach that address directly, but there is no secret protecting the endpoint.
- They take no input (the request is read and discarded), so there is nothing to inject into. The worst a caller can do is send a Wake-on-LAN packet to the one configured MAC or read the status sentence.
- `TriggerLimitIntervalSec`/`TriggerLimitBurst` stop floods, but they also mean a noisy local client can make systemd stop accepting on the socket for a while. That is a local denial of service: the hook refuses connections until the limit window passes.
- Each connection is capped at 10 seconds of runtime (`RuntimeMaxSec`) and the handlers give up reading headers after 3 seconds.

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

If you use `ufw`, allow only the n8n compose network to reach those two ports. Read its subnet with `docker network inspect` (run it after `docker compose up`, from the module folder):

```bash
SUBNET=$(docker network inspect siri-voice-bridge_default -f '{{(index .IPAM.Config 0).Subnet}}')   # for example 172.18.0.0/16
sudo ufw allow from "$SUBNET" to "$BRIDGE_IP" port 8643,8644 proto tcp
```

Avoid the broad `172.16.0.0/12` range: it admits every container on the host, not just n8n. The network name is `<folder>_default`; check `docker network ls` if you renamed the folder.

The compose project creates its own network, so the container reaches the host through `host.docker.internal`, which resolves to the default bridge gateway. If that does not work on your host, use the gateway of the compose network instead.

Edit `CHECKS` in `status/status.py` to describe your own services. Wake-on-LAN also needs to be enabled in the target machine's firmware and NIC settings.
