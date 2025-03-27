# Velocity Protocol - Censorship-Resistant Messaging on AO/Arweave

## Overview

**RegistryProcess** : `dVL1cJFikqBQRbtHQiOxwto774TilKtrymfcaQO8HGQ`

Welcome to `SpaceTurtle-Dao/velocity-protocol`, the home of the **Velocity Protocol**—a lightweight, open protocol for creating a censorship-resistant global messaging and operational network within the AO/Arweave ecosystem. Built by SpaceTurtle-DAO, Velocity leverages decentralized **Hub Zones** to host messages and **Registry Zones** to enable their discovery, combining cryptographic security with modular design.

This repository contains:
- **VIPs (Velocity Improvement Proposals)**: Specifications for the protocol’s message types, filtering, and extensions (e.g., `vips/01.md` for basic flow).
- **Documentation**: This README and related guides for implementing Velocity.

Velocity integrates with the Zone framework from [`permaweb-libs/specs/spec-zones.md`](https://github.com/permaweb/permaweb-libs/blob/main/specs/spec-zones.md), using:
- **[Registry Zones](./zones/registry.lua)**: Manage and discover hubs via `registry.lua`.
- **[Hub Zones](./zones/hub.lua)**: Host messages via `hub.lua`.

## Purpose

Velocity Protocol aims to provide a simple, resilient messaging system for the permaweb, addressing key needs:
- **Censorship Resistance**: No central server reliance, using decentralized hubs secured by cryptographic signatures.
- **Global Accessibility**: Hubs register with registries, enabling clients to find and connect to them worldwide.
- **Operational Flexibility**: Supports social messaging (e.g., text notes, reactions) and workflows, extensible via VIPs.
- **Interoperability**: Aligns with AO’s process model and Arweave’s permanent storage.

## Features

- **Lightweight Design**: Optimized for AO’s environment, avoiding heavy P2P overhead.
- **Cryptographic Security**: Messages are signed with public-key cryptography for authenticity and tamper-proofing.
- **Flexible Messaging**: Defines `Kind` tags (e.g., `1` for text notes, `7` for reactions) per VIP-01.
- **Decentralized Ecosystem**: Hubs host messages, registries enable discovery, all as AO processes.
- **Extensibility**: VIPs allow community-driven enhancements (e.g., media attachments, reactions).

## How It Works

1. **Hubs**: Decentralized AO processes (via `hub.lua`) store and serve messages (ANS-104 objects) with `Kind` tags, notifying followers of owner events.
2. **Registries**: Registry Zones (via `registry.lua`) allow hubs to self-register with a `msg.Data` spec (e.g., `{"type": "hub", "kinds": [1, 7]}`), making them discoverable.
3. **Clients**: Users publish messages to hubs and fetch them using `FetchEvents`, discovering hubs via registries with `Kind` filtering (e.g., `Kind: "hub"`).

## Setup

### Prerequisites
- **AO Environment**: Install AOS or a similar AO client to deploy processes.
- **Repositories**:
  - Clone [`Zones`](https://github.com/SpaceTurtle-Dao/Zonest) for `registry.lua`.
  - Clone [`Hubs`](https://github.com/SpaceTurtle-Dao/Hubs/tree/development) for `hub.lua`.

### Installation

1. **Clone Repo**:
   ```bash
   git clone https://github.com/SpaceTurtle-Dao/Zones.git
   ```

2. **Deploy Registry Zone**:
   ```bash
   cd Zones
   aos --load registry.lua
   ```

3. **Deploy Hub Zone**:
   ```bash
   cd Zones
   aos --load hub.lua
   ```