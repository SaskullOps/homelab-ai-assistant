# Security policy

## Intended exposure

- Run n8n bound to `127.0.0.1` (the compose file does this) and publish only the webhook path through a tunnel or a VPN. Never expose the n8n editor.
- Authentication is a random, unguessable path plus a secret header token. Generate both with `openssl rand`, store them in a password manager, and rotate them if a phone is lost.
- Keep the public voice path read-only. Do not attach tools that delete, send, pay or execute commands to the model behind it. Use the confirmation pattern for anything that writes.
- Optional hooks (`examples/`) listen on the Docker bridge only and accept no input.
- Keep `.env` out of version control (it is git-ignored) and out of screenshots.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use GitHub's private vulnerability reporting ("Security" tab, "Report a vulnerability") on this repository. Include what you found, how to reproduce it, and the affected version. You will get an answer within a few days; this is a hobby project, so there is no formal SLA.

## Supported versions

Only the latest commit on `main`.
