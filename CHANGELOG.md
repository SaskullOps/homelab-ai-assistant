# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-10-23

### Added
- `siri-voice-bridge`: an Apple Watch and iPhone Shortcut talks to an n8n router (header token, random path) that answers through any OpenAI-compatible endpoint, with optional status and Wake-on-LAN hooks.
- Docker Compose quick start, import and test scripts, Shortcut guide, troubleshooting from real errors, measured latency and cost.
- Hardened defaults after an independent security review: no stored executions, token kept out of argv, bounded hook runtime, image pinned by digest.
