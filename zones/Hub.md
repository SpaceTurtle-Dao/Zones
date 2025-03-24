# Hub Zone Kind

## Overview
A **Hub Zone** is a decentralized node hosting messages for the Velocity Protocol, registered with `registry.lua` for discovery. It aligns with `velocity-protocol`’s hub concept and uses the Zone framework from `permaweb-libs/specs/spec-zones.md`.

## Spec Structure
Defined in `msg.Data` per `spec-zones.md`:
- **`type`**: `"hub"` (string) - Maps to `Zone-Type: Channel`, filterable via `Kind: "hub"`.
- **`kinds`**: Array of integers - Supported Velocity message kinds (e.g., `[1, 7]` for text notes and reactions).
- **`description`**: (optional) String - Purpose (e.g., `"Social message hub"`).

### Transaction Tags
- `Data-Protocol: Zone`
- `Zone-Type: Channel`

### Example
```json
{
  "type": "hub",
  "kinds": [1, 7],
  "description": "Social message hub"
}