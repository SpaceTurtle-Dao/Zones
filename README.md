# Velocity Protocol - Censorship-Resistant Messaging on AO/Arweave

## Overview

**RegistryProcess** : `dVL1cJFikqBQRbtHQiOxwto774TilKtrymfcaQO8HGQ`

Welcome to `SpaceTurtle-Dao/velocity-protocol`, the home of the **Velocity Protocol**—a lightweight, open protocol for creating a censorship-resistant global messaging and operational network within the AO/Arweave ecosystem. Built by SpaceTurtle-DAO, Velocity leverages decentralized **Hub Zones** to host messages and **Registry Zones** to enable their discovery, combining cryptographic security with modular design.

This repository contains:
- **VIPs (Velocity Improvement Proposals)**: Specifications for the protocol’s message types, filtering, and extensions (e.g., `vips/01.md` for basic flow).
- **Documentation**: This README and related guides for implementing Velocity.

## What is the Velocity Protocol?

The Velocity Protocol is a streamlined, extensible messaging system designed for the permaweb—the permanent, decentralized web powered by Arweave’s immutable storage and AO’s process-driven computation. Instead of relying on centralized servers, Velocity distributes message hosting across **Hub Zones** and uses **Registry Zones** for discovery, all secured by cryptographic signatures. Key features include:

- **Censorship Resistance**: Decentralized hubs eliminate single points of control.
- **Cryptographic Security**: Messages are signed with public-key cryptography for authenticity and integrity.
- **Lightweight Design**: Optimized for AO, avoiding the complexity of traditional P2P systems.
- **Extensibility**: Velocity Improvement Proposals (VIPs) enable community-driven enhancements.

Velocity defines message types (via “Kinds”), filtering mechanisms, and a Zone-based architecture, making it perfect for social features like posts, follows, and reactions—think of it as a decentralized foundation for platforms like Twitter or Mastodon.

---

Velocity integrates with the Zone framework from [`permaweb-libs/specs/spec-zones.md`](https://github.com/permaweb/permaweb-libs/blob/main/specs/spec-zones.md), using:
- **[Registry Zones](./zones/registry.lua)**: Manage and discover hubs via `registry.lua`.
- **[Hub Zones](./zones/hub.lua)**: Host messages via `hub.lua`.

## How It Works

1. **Hubs**: Decentralized AO processes (via `hub.lua`) store and serve messages (ANS-104 objects) with `Kind` tags, notifying followers of owner events.
2. **Registries**: Registry Zones (via `registry.lua`) allow hubs to self-register with a `msg.Data` spec (e.g., `{"type": "hub", "kinds": [1, 7]}`), making them discoverable.
3. **Clients**: Users publish messages to hubs and fetch them using `FetchEvents`, discovering hubs via registries with `Type` filtering (e.g., `type: "hub"`).

## Setup

### Prerequisites
- **AO Environment**: Install AOS or a similar AO client to deploy processes.
- **Repositories**:
  - Clone [`Zones`](https://github.com/SpaceTurtle-Dao/Zonest) for `registry.lua`.
  - Clone [`Hubs`](https://github.com/SpaceTurtle-Dao/Hubs/tree/development) for `hub.lua`.

## Zones: The Modular Core of Velocity

Velocity builds on **Zones**, programmable entities defined in `permaweb-libs/specs/spec-zones.md`. Zones are AO processes that can represent anything from users to channels. Velocity uses two key Zone types to power its ecosystem:

### 1. Hub Zones (`hub.lua`)
Hub Zones are decentralized nodes that host and serve messages. Classified as `Zone-Type: Channel`, they manage Velocity messages—ANS-104 objects tagged with `Kind` values, such as:
- `Kind: 1` for text notes (e.g., posts),
- `Kind: 3` for follow lists,
- `Kind: 7` for reactions (e.g., likes).

Implemented in `hub.lua`, Hub Zones:
- **Store Messages**: Accept and persist user-submitted events.
- **Manage Followers**: Track followers via `Kind: 2` messages (`+` to follow, `-` to unfollow) and notify them of owner updates.
- **Serve Queries**: Handle `FetchEvents` requests with filters for `Kind`, author, timestamp, etc.

For instance, a user posts a `Kind: 1` note to a hub, which stores it and notifies followers. Unlike earlier iterations, Hub Zones no longer self-register—they operate independently, and their discovery relies on external registration with a Registry Zone.

### 2. Registry Zones (`registry.lua`)
Registry Zones, tagged as `Zone-Type: Registry`, serve as generic directories for all Zone types—not just hubs. Implemented in `registry.lua`, they allow any Zone to register its process ID (`msg.From`) and spec (e.g., `{"type": "hub", "kinds": [1, 7]}`). Clients query these registries to discover Zones based on type, metadata, or other criteria.

This generic approach makes Registry Zones versatile, supporting hubs, user profiles, or any future Zone type, while keeping Velocity’s ecosystem flexible and decentralized.

---

## Crafting a Social Media Experience with Velocity

Velocity weaves Hub and Registry Zones into a robust social media framework:

1. **Publishing Messages**: Users send signed messages (e.g., a `Kind: 1` post) to a Hub Zone, which validates and stores them.
2. **Follower Propagation**: Hubs notify followers (tracked via `Kind: 2`) of new owner events, creating a real-time feed.
3. **Fetching Content**: Clients use `FetchEvents` with filters (e.g., `{ "kinds": [1], "authors": ["pubkey"] }`) to retrieve posts or reactions from hubs.
4. **Discovery**: Clients query a Registry Zone to find hubs or other Zones, using filters like `{"spec": {"type": "hub"}}`.

This enables familiar social features:
- **Posts**: `Kind: 1` notes for user-generated content.
- **Follows**: `Kind: 3` messages to manage follow lists, updated as users connect or disconnect.
- **Reactions**: `Kind: 7` messages for likes or replies, with deduplication logic.
- **Profiles**: `Kind: 0` messages for user metadata (e.g., name, avatar).

VIPs, such as VIP-05, extend this with media attachments (e.g., images or videos), enriching the user experience.

---

## Harmony with AO’s Architecture

AO’s process-based compute layer, built on Arweave’s permanent storage, is tailor-made for Velocity:

- **Process-Driven Hubs**: Hub Zones run as AO processes via `hub.lua`. AO’s lightweight execution model ensures efficiency without complex networking.
- **Immutable Storage**: Messages stored as ANS-104 objects in hubs benefit from Arweave’s permanence, guaranteeing long-term availability.
- **Message Passing**: Velocity’s event model (e.g., `Event` and `FetchEvents` handlers) aligns with AO’s asynchronous, message-driven communication.
- **Cryptographic Foundations**: AO’s use of public-key cryptography for process identity and messaging ensures Velocity’s security and trustworthiness.

By using hubs as decentralized yet manageable nodes (rather than full P2P), Velocity optimizes for AO’s environment. Registry Zones enhance discoverability without centralizing control, striking a balance between usability and decentralization.

---

## Developer Guide: Building with Velocity

Ready to create a decentralized social app? Here’s a step-by-step guide:

### 1. Set Up Your Environment
- Install an AO client (e.g., AOS).
- Clone the Zones repository:
  ```bash
  git clone https://github.com/SpaceTurtle-Dao/Zones.git
  ```

### 2. Deploy a Registry Zone
- Run `registry.lua`:
  ```bash
  cd Zones
  aos --load registry.lua
  ```
- Record the process ID (e.g., `dVL1cJFikqBQRbtHQiOxwto774TilKtrymfcaQO8HGQ`).

### 3. Deploy a Hub Zone
- Run `hub.lua`:
  ```bash
  aos --load hub.lua
  ```
- Manually register it with the Registry Zone:
  ```json
  {
    "Target": "<registry-process-id>",
    "Action": "Register",
    "Data": "{\"type\": \"hub\", \"kinds\": [1, 7], \"description\": \"Social hub\"}"
  }
  ```

### 4. Post a Message
- Send a `Kind: 1` message to the hub:
  ```json
  {
    "Target": "<hub-process-id>",
    "Action": "Event",
    "Kind": "1",
    "Content": "Hello from the permaweb!"
  }
  ```

### 5. Retrieve Messages
- Query the hub:
  ```json
  {
    "Target": "<hub-process-id>",
    "Action": "FetchEvents",
    "Filters": "[{\"kinds\": [1]}]"
  }
  ```

### 6. Discover Hubs
- Query the registry:
  ```json
  {
    "Target": "<registry-process-id>",
    "Action": "GetZones",
    "Filters": "{\"spec\": {\"type\": \"hub\"}}"
  }
  ```

### 7. Extend Functionality
- Implement VIPs (e.g., VIP-05 for media) or propose new `Kind` types to customize your app.

---
