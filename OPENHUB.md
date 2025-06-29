# Velocity Protocol Open Hub

A fully compliant public hub implementation for the [Velocity Protocol](https://github.com/SpaceTurtle-Dao/velocity-protocol), providing censorship-resistant messaging infrastructure on the AO/Arweave ecosystem.

## Overview

The Open Hub (`openhub.lua`) is a decentralized message hub that implements all Velocity Improvement Proposals (VIPs) for a complete, production-ready messaging experience. It serves as a public, permissionless hub that accepts messages from any user while maintaining security and spam protection.

## Features

### ✅ VIP Compliance

- **VIP-01**: Protocol flow, message validation, and ANS-104 message signing
- **VIP-02**: Follow lists and social graph management
- **VIP-03**: Text messages, replies, and threading support  
- **VIP-04**: Reactions and social interactions with deduplication
- **VIP-05**: Media attachments and content handling (framework ready)
- **VIP-06**: Process requirements and hub discovery via Zones Registry
- **VIP-07**: Security guidelines and best practices

### 🛡️ Security Features

- No message size limits (Arweave permanence)
- No rate limiting (accepts unlimited messages)
- Author ban/trust lists
- Enhanced ANS-104 signature validation
- Comprehensive VIP message validation
- Detailed error reporting with VIP compliance codes

### 🌐 Public Hub Features

- **Open Access**: Accepts messages from any author
- **Unlimited Capacity**: Events persist forever (no limits)
- **Auto-Registration**: Automatically registers with Zones Registry
- **Health Monitoring**: Built-in health check endpoints
- **Real-time Broadcast**: Events are broadcast to followers
- **High Performance**: Hash-based indexing for fast lookups
- **Advanced Search**: Optimized content and metadata search

## Supported Message Kinds

| Kind | Type | VIP | Description |
|------|------|-----|-------------|
| `0` | Profile Update | VIP-02 | User profile metadata |
| `1` | Note/Reply | VIP-03 | Text messages and replies |
| `3` | Follow | VIP-02 | Follow list updates |
| `7` | Reaction | VIP-04 | Reactions to messages |

## Quick Start

### Prerequisites

- [AOS](https://github.com/permaweb/aos) installed (`npm i -g https://get_ao.g8way.io`)
- Node.js v18+ for deployment script

### Deployment

1. **Deploy using the automated script:**
   ```bash
   node deploy-openhub.js
   ```

2. **Manual deployment:**
   ```bash
   # Start AOS with hub configuration
   aos --name velocity-openhub --tag-name Velocity-Hub --tag-name Open-Hub
   
   # Load the hub script
   .load zones/openhub.lua
   ```

3. **Register with Zones Registry (automatic):**
   The hub will automatically register itself with the default registry every hour.

## API Reference

### Core Handlers

#### `Event`
Processes incoming Velocity protocol messages.

**Tags:**
- `Action: Event`
- `Kind: <message_kind>`

**Example:**
```lua
Send({
    Target = "<hub_process_id>",
    Action = "Event",
    Kind = "1",
    Content = "Hello, Velocity Protocol!",
    Data = '{"content": "Hello, Velocity Protocol!"}'
})
```

#### `FetchEvents`  
Retrieves filtered events from the hub.

**Tags:**
- `Action: FetchEvents`
- `Filters: <json_filters>` (optional)

**Filter Parameters:**
- `ids`: Array of event IDs
- `authors`: Array of author addresses
- `kinds`: Array of message kinds
- `since`: Timestamp filter (after)
- `until`: Timestamp filter (before)
- `limit`: Maximum results (default: 100, max: 1000)
- `search`: Text search in content

**Example:**
```lua
Send({
    Target = "<hub_process_id>",
    Action = "FetchEvents",
    Filters = '[{"kinds": ["1"], "limit": 50}]'
})
```

#### `Info`
Returns hub information and statistics.

**Example Response:**
```json
{
    "User": "<owner_address>",
    "Spec": {
        "type": "hub",
        "description": "Open Public Velocity Protocol Hub",
        "version": "1.0",
        "kinds": [1, 3, 7],
        "isPublic": true
    },
    "Stats": {
        "totalEvents": 1337,
        "followers": 42,
        "following": 13
    }
}
```

### Message Formats

#### Text Note (Kind 1)
```json
{
    "Kind": "1",
    "Content": "Your message text",
    "timestamp": 1234567890
}
```

#### Reply (Kind 1 with marker)
```json
{
    "Kind": "1", 
    "Content": "Reply text",
    "marker": "reply",
    "e": "<original_event_id>",
    "p": "<original_author>"
}
```

#### Follow List (Kind 3)
```json
{
    "Kind": "3",
    "p": "[\"<author1>\", \"<author2>\"]"
}
```

#### Reaction (Kind 7)
```json
{
    "Kind": "7",
    "Content": "👍",
    "e": "<target_event_id>",
    "p": "<target_author>"
}
```

## Hub Configuration

The hub can be configured by modifying the `State` object in `openhub.lua`:

```lua
State = {
    Spec = {
        maxEventLimit = 50000,    -- Maximum stored events
        kinds = {1, 3, 7},        -- Supported message kinds
        isPublic = true           -- Accept all messages
    },
    Security = {
        spamFilters = true              -- Enable spam filtering
    },
    Registration = {
        autoRegister = true,            -- Auto-register with registry
        registrationInterval = 3600000  -- 1 hour
    }
}
```

## Integration Examples

### Client Integration

```javascript
// Send a message to the hub
await ao.send({
    process: hubProcessId,
    tags: [
        { name: "Action", value: "Event" },
        { name: "Kind", value: "1" }
    ],
    data: JSON.stringify({
        content: "Hello from my client!"
    })
});

// Fetch recent messages
const response = await ao.send({
    process: hubProcessId,
    tags: [
        { name: "Action", value: "FetchEvents" },
        { name: "Filters", value: JSON.stringify([{
            kinds: ["1"],
            limit: 20
        }])}
    ]
});
```

### Hub Discovery

```lua
-- Find public hubs via registry
Send({
    Target = "<registry_process_id>",
    Action = "GetZones",
    Filters = '{"spec": {"type": "hub", "isPublic": true}}'
})
```

## Security Considerations

1. **Enhanced Validation**: Comprehensive VIP and ANS-104 message validation
2. **Ban Lists**: Problematic authors can be banned
3. **Detailed Error Responses**: Clear error messages with VIP compliance codes
4. **No Size Limits**: Accepts messages of any size
5. **No Rate Limits**: Accepts unlimited messages from any author
6. **Permanent Storage**: Events persist forever (Arweave principle)

## Monitoring and Health

### Health Check
```lua
Send({
    Target = "<hub_process_id>",
    Action = "Health"
})
```

### Event Statistics
The hub tracks:
- Total events stored
- Number of followers/following
- Messages per author
- Registration status

## Contributing

This implementation follows the Velocity Protocol specifications. When contributing:

1. Ensure VIP compliance
2. Maintain backward compatibility
3. Add appropriate tests
4. Update documentation

## License

Public Domain - Use freely for any purpose.

## Related Projects

- [Velocity Protocol](https://github.com/SpaceTurtle-Dao/velocity-protocol) - Main protocol specification
- [AO Cookbook](https://cookbook.ao.dev) - AO development resources
- [Zones Registry](./Registry.md) - Hub discovery system

---

**Process ID**: Will be generated during deployment  
**Registry**: `qrXGWjZ1qYkFK4_rCHwwKKEtgAE3LT0WJ-MYhpaMjtE`  
**Version**: 1.0  
**Status**: Production Ready ✅