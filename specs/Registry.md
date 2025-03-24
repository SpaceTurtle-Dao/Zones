# Registry Zone Kind

## Overview
A **Registry Zone** registers and lists other zones, like `registry.lua`, enabling hierarchical discovery on the permaweb.

## Spec Structure
Defined in `msg.Data` per `spec-zones.md`:
- **`type`**: `"registry"` (string) - Maps to `Zone-Type: Registry` (inferred extension), filterable via `Kind: "registry"`.
- **`description`**: String - Purpose (e.g., `"Zone registry"`).
- **`version`**: String - Version (e.g., `"0.1"`).
- **`parent`**: (optional) String - Parent registry ID (e.g., `"reg0"`).

### Transaction Tags
- `Data-Protocol: Zone`
- `Zone-Type: Registry` (custom extension)

### Example
```json
{
  "type": "registry",
  "description": "Zone registry for hubs and users",
  "version": "0.1",
  "parent": "reg0"
}