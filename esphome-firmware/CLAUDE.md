# Claude Code Instructions

Apply the same rules as `AGENTS.md` in this directory. The key expectations are repeated here so they are visible to tools that prefer `CLAUDE.md`.

- Work only inside `esphome-firmware/` unless explicitly asked otherwise.
- Keep device YAMLs in `devices/` and shared building blocks in `packages/`.
- Prefer reusable packages over duplicated YAML.
- Preserve stable device names and entity IDs unless the user requests a breaking change.
- Never commit or invent real values for `secrets.yaml`, Wi-Fi credentials, API keys, or encryption keys.
- Do not guess GPIO mappings or hardware details; surface assumptions clearly.
- Keep fallback Wi-Fi, OTA, and logging unless there is a strong reason to change them.
- Validate with `./scripts/validate.sh <device-yaml>` when possible, and report honestly if ESPHome is unavailable.
