# Hub - A Decentralized Message Hub

## Overview

`Hub.lua`, implements **Hub Zones**—decentralized nodes that host messages for the [Velocity Protocol](https://github.com/SpaceTurtle-Dao/velocity-protocol). Hub Zones are a specific type of Zone as defined in [`permaweb-libs/specs/spec-zones.md`](https://github.com/permaweb/permaweb-libs/blob/main/specs/spec-zones.md), categorized as `Zone-Type: Channel`. They provide a censorship-resistant messaging infrastructure within the AO/Arweave ecosystem, registered and discoverable via the [`registry.lua` Registry Zone](https://github.com/SpaceTurtle-Dao/Zones).

The core implementation, `hub.lua`, handles message storage, follower management, and event fetching per `velocity-protocol`’s specifications.

## Purpose

Hub Zones are the backbone of Velocity’s messaging system, enabling:
- **Message Hosting**: Store and serve Velocity messages (ANS-104 objects) like text notes (`Kind: 1`), reactions (`Kind: 7`), and follow lists (`Kind: 3`).
- **Decentralized Discovery**: Register with `registry.lua` for clients to locate hubs.
- **Social Features**: Manage followers and propagate events to them, supporting a decentralized social network.

## Features

- **Self-Registration**: Hubs register with `registry.lua` using their process ID (`msg.From`).
- **Dynamic Updates**: Update metadata (e.g., supported kinds) via the `Register` handler.
- **Message Serving**: Handle `FetchEvents` requests with filtering by `Kind`, `authors`, and more.
- **Follower Management**: Track followers (`Kind: 2` with `+`/`-`) and notify them of owner events.
- **Event Processing**: Support Velocity-specific events (e.g., deduplicate reactions, update follow lists).

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