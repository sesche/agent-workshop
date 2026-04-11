# Copilot Instructions

This subproject contains ESPHome firmware definitions.

- Restrict changes to `esphome-firmware/` unless the task explicitly spans multiple projects.
- Put per-device configuration into `devices/` and shared logic into `packages/`.
- Prefer small, reviewable YAML edits and reusable packages over copy-paste duplication.
- Preserve stable names, IDs, and working connectivity defaults unless the user asks for a breaking change.
- Never add real secrets or credentials to tracked files; use placeholders in `secrets.example.yaml` only.
- Do not guess pin mappings, board variants, or hardware wiring. If an assumption is unavoidable, make it explicit.
- Validate changed configs with `./scripts/validate.sh <device-yaml>` when local tooling is available.
