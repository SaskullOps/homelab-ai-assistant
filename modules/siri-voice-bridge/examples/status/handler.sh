#!/bin/bash
# Runs once per connection (systemd Accept=yes): stdin/stdout are the socket.
while IFS= read -r -t 2 line; do
  [ -z "$line" ] || [ "$line" = $'\r' ] && break
done
body=$(/usr/bin/python3 /usr/local/lib/siri-bridge/status.py)
printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
  "$(printf %s "$body" | wc -c)" "$body"
