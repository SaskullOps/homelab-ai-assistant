# homelab-ai-assistant

An AI assistant for a home lab: voice, documents and safe actions. Small modules you can install one at a time, each built around the same rule: the assistant can look at everything, but changes need a human tap.

## Modules

| Module | What it does | Status |
|--------|--------------|--------|
| [`siri-voice-bridge`](modules/siri-voice-bridge/README.md) | Ask your lab questions, check its status or wake a machine from an Apple Watch or iPhone, through one hardened n8n webhook. | Available |
| `telegram-confirm` | Confirmation step for actions that change things: the assistant proposes, you tap approve on Telegram. | Coming soon |
| `docs-rag` | Ask questions about your own documents with a local model, nothing leaves the house. | Coming soon |
| `pricewatch` | Watch product prices and get a message when one drops. | Coming soon |

## Quick look

```bash
cd modules/siri-voice-bridge
cp .env.example .env     # then fill the three secrets, see the module README
docker compose up -d
scripts/import.sh && scripts/test.sh
```

## Principles

- Self-hosted first: n8n plus any OpenAI-compatible endpoint, local or cloud.
- Everything exposed to the internet is a single authenticated path, never an admin UI.
- The voice and chat paths are read-only by default.
- No secrets in the repository: configuration is `.env`, and only `.env.example` is committed.

## Security

See [SECURITY.md](SECURITY.md) for how the modules are meant to be exposed and how to report a problem.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
