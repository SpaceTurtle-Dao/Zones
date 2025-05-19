[![protocol.land](https://arweave.net/eZp8gOeR8Yl_cyH9jJToaCrt2He1PHr0pR4o-mHbEcY)](https://protocol.land/#/repository/<REPO_ID>)

# Registry - Zone Registry for AO/Arweave Ecosystem

## Overview

`registry.lua` is a Lua script implementing a **Registry Zone** within the AO/Arweave ecosystem, designed to register and manage Zones as defined in [`permaweb-libs/specs/spec-zones.md`](https://github.com/permaweb/permaweb-libs/blob/main/specs/spec-zones.md). It provides a generic, dynamic, and scalable solution for discovering and organizing Zones—modular, programmable entities representing users, organizations, channels, and more. Built by SpaceTurtle-DAO, this registry supports self-registration and updates, ensuring authenticity and flexibility.

This repository contains:
- `registry.lua`: The core script for the Registry Zone.
- `specs/`: Documentation for supported Zone Kinds (see below).

## Purpose

The Registry Zone addresses the need for a decentralized directory in the AO ecosystem, enabling:
- **Discovery**: Clients can find Zones (e.g., Velocity hubs, user profiles) by type and metadata.
- **Management**: Zones self-register and update their specs, maintaining a live, trusted index.
- **Interoperability**: Aligns with `spec-zones.md` and integrates with `velocity-protocol` for hub discovery.

## Features

- **Self-Registration**: Zones register using their own process ID (`msg.From`), ensuring authenticity.
- **Updates**: Zones can update their metadata dynamically via the `Register` handler.
- **Filtering and Paging**: The `GetZones` handler supports filtering by `Kind` (e.g., `"hub"`) and spec fields, with pagination for scalability.