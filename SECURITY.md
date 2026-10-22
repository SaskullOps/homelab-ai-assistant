# Security policy

## Intended exposure

- Run n8n bound to `127.0.0.1` (the compose file does this) and publish only the webhook path through a tunnel or a VPN. Never expose the n8n editor.
- Authentication is a random path plus a secret header token. Generate both with `openssl rand`, keep them in a password manager, and rotate them if a phone is lost.
- Keep the public voice path read-only. Do not give the model behind it tools that delete, send, pay or run commands. Anything that writes needs a confirmation step.
- The optional hooks (`examples/`) listen on the Docker bridge only and accept no input, but they have no authentication: any local process or container that reaches that address can trigger them. Restrict the firewall rule to the compose subnet.
- A stolen token is worth as much as the tools of the model behind the endpoint, and user text reaches that model unfiltered. Point the voice path at a read-only model or agent.
- n8n keeps no execution data, because it would contain the token and the questions. Keep it that way.
- Keep `.env` out of version control (it is git-ignored) and out of screenshots.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use GitHub's private vulnerability reporting (the "Security" tab, then "Report a vulnerability") on this repository. Say what you found, how to reproduce it and which version it affects. I will answer within a few days. This is a hobby project, so there is no formal SLA.

## Supported versions

Only the latest commit on `main`.
