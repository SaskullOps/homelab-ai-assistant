#!/bin/bash
# Runs once per connection (systemd Accept=yes): stdin/stdout are the socket.
# Drain the request so the client never sees a connection reset, then act.
while IFS= read -r -t 2 line; do
  [ -z "$line" ] || [ "$line" = $'\r' ] && break
done
/usr/bin/python3 /usr/local/lib/siri-bridge/wol.py "${TARGET_MAC:?TARGET_MAC not set}" >&2
printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok'
