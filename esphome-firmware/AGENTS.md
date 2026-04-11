# ESPHome Firmware Agent Instructions

This file is the canonical instruction set for AI coding agents in this subproject.

## Mission

Work only inside `esphome-firmware/` unless the user explicitly asks for a cross-project change. Keep edits small, safe, and easy to review.

## Project Layout

- Put device-specific firmware definitions in `devices/`.
- Put reusable shared configuration in `packages/`.
- Keep helper tooling in `scripts/`.
- Treat `secrets.yaml` as local-only and never create, modify, or commit real credentials.

## ESPHome Editing Rules

- Prefer reusable packages over copying the same YAML into multiple device files.
- Keep device names stable and use lowercase kebab-case for new device identifiers.
- Preserve existing entity IDs and names unless the user asks for a breaking change.
- Do not guess GPIO mappings, sensor models, or board variants. If hardware assumptions are necessary, state them in comments or in the final summary.
- Use `substitutions:` for repeated names or values that improve readability.
- Prefer additive changes over broad rewrites of working device configurations.

## Safety Rules

- Never put real secrets, API keys, Wi-Fi credentials, tokens, or encryption keys into tracked files.
- Use `secrets.example.yaml` only for placeholders.
- Do not remove fallback access, OTA, or logging without a clear reason from the user.
- Call out any change that could affect flashing, connectivity, pin assignments, or entity naming.

## Validation

- When possible, validate changed device files with `./scripts/validate.sh <device-yaml>`.
- If ESPHome is not installed locally, say so instead of pretending validation succeeded.

## Collaboration Style

- Prefer concise explanations and mention any assumptions.
- If there is already an established pattern in this subproject, follow it.
- Keep comments short and only add them where they reduce hardware-related ambiguity.
