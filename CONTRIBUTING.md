# Contributing

Issues and pull requests are welcome. I would most like other speech front ends, hardened versions of the optional hooks, and translations of the spoken messages.

- Keep changes small and focused, and use conventional commits (`feat:`, `fix:`, `docs:`).
- Never commit secrets, real domains, IP addresses or screenshots that show them. Use placeholders such as `example.com` and `<your-host>`.
- If you change the workflow, test it from a fresh clone: `docker compose up -d`, `scripts/import.sh`, `scripts/test.sh`. Re-export `n8n/siri-router.json` with the webhook path set back to the `__SIRI_ROUTER_PATH__` placeholder and credential ids intact.
