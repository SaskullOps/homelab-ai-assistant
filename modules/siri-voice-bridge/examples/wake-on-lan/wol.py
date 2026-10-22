#!/usr/bin/env python3
"""Send one Wake-on-LAN magic packet. Usage: wol.py AA:BB:CC:DD:EE:FF [broadcast_ip]"""
import socket
import sys

mac = sys.argv[1].replace(":", "").replace("-", "")
if len(mac) != 12:
    sys.exit("invalid MAC address")
packet = b"\xff" * 6 + bytes.fromhex(mac) * 16
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    s.sendto(packet, (sys.argv[2] if len(sys.argv) > 2 else "255.255.255.255", 9))
