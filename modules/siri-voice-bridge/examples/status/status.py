#!/usr/bin/env python3
"""Print one spoken sentence about which of your services answer.

Edit CHECKS: (spoken name, host, TCP port). Keep it read-only and fast.
"""
import socket

CHECKS = [
    ("the dashboard", "127.0.0.1", 3000),
    ("the media server", "127.0.0.1", 8096),
]


def up(host, port):
    try:
        with socket.create_connection((host, port), timeout=1.5):
            return True
    except OSError:
        return False


down = [name for name, host, port in CHECKS if not up(host, port)]
if down:
    print("Problem: " + ", ".join(down) + (" is" if len(down) == 1 else " are") + " not answering.")
else:
    print(f"All {len(CHECKS)} checks are fine.")
