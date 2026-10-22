#!/bin/bash
# Runs once per connection (systemd Accept=yes): stdin/stdout are the socket.
# Drain the request headers with a hard overall deadline (3 s, 64 lines, 8 KiB per line).
deadline=$((SECONDS + 3)); n=0
while [ "$SECONDS" -lt "$deadline" ] && [ "$n" -lt 64 ] && IFS= read -r -t 1 -n 8192 line; do
  n=$((n + 1))
  if [ -z "$line" ] || [ "$line" = $'\r' ]; then break; fi
done
/usr/bin/python3 /usr/local/lib/siri-bridge/wol.py "${TARGET_MAC:?TARGET_MAC not set}" >&2
printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok'
