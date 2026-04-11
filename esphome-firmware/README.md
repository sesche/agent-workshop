# ESPHome Firmware Workspace

This subproject is a small but practical starting point for developing ESPHome-based firmwares.

## Structure

- `devices/`: one YAML file per device
- `packages/`: reusable shared building blocks
- `scripts/`: helper scripts for local validation
- `AGENTS.md`: canonical AI instructions for this subproject
- `CLAUDE.md` and `.github/copilot-instructions.md`: compatibility mirrors for common coding agents

## Getting Started

1. Copy `secrets.example.yaml` to `secrets.yaml`.
2. Adjust the secret values for your environment.
3. Duplicate `devices/example-esp32-devkit.yaml` for a real device.
   For an ESP32-C3 that should trigger an optocoupler for a radio remote, you can start directly from `devices/esp32-c3-833mhz-smart-remote.yaml`.
4. Validate the configuration:

```bash
./scripts/validate.sh devices/example-esp32-devkit.yaml
./scripts/validate.sh devices/esp32-c3-833mhz-smart-remote.yaml
```

5. Build or flash with ESPHome:

```bash
esphome run devices/example-esp32-devkit.yaml
esphome run devices/esp32-c3-833mhz-smart-remote.yaml
```

## Conventions

- Keep one device definition per file in `devices/`.
- Move shared logic to `packages/` instead of copying large YAML blocks.
- Never commit `secrets.yaml` or real credentials.
- Document hardware-specific assumptions near the changed configuration.
- For optocoupler-triggered inputs, set the correct GPIO and signal polarity before flashing.
