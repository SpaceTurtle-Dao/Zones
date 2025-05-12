-- Required Libraries
local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")

Variant = "0.0.1"
RegistryProcess = "dVL1cJFikqBQRbtHQiOxwto774TilKtrymfcaQO8HGQ"

Kinds = {
    PROFILE_UPDATE = "0",
    NOTE = "1",
    FOLLOW = "3",
    WRAPPED_SEAL = "6",
    DELETE = "7",
    GOSSIP = "1000"
}

State = {
    Events = Events or {},
    Owner = Owner,
    Spec = {
        type = "hub",
        description = "Social message hub",
        version = "0.1"
    }
}

-- Helpers
local function getTag(tags, key)
    for _, tag in ipairs(tags or {}) do
        if tag[1] == key then return tag[2] end
    end
    return nil
end

local function hasSeenReference(sig)
    for _, e in ipairs(State.Events) do
        if e.Kind == Kinds.GOSSIP and getTag(e.Tags, "reference-signature") == sig then
            return true
        end
    end
    return false
end

local function getFollowList(events, from)
    local profileUpdates = utils.filter(function(e)
        return e.Kind == Kinds.FOLLOW and e.From == from
    end, events)

    if #profileUpdates == 0 then return {} end

    local latest = profileUpdates[#profileUpdates]
    local list = {}

    for _, tag in ipairs(latest.Tags or {}) do
        if tag[1] == "p" then table.insert(list, tag[2]) end
    end

    return list
end

local function getFollowers(events, pubkey)
    local followers = {}

    for _, e in ipairs(events) do
        if e.Kind == Kinds.FOLLOW then
            for _, tag in ipairs(e.Tags or {}) do
                if tag[1] == "p" and tag[2] == pubkey then
                    table.insert(followers, e.From)
                    break
                end
            end
        end
    end

    return followers
end

local function broadcastToFollowers(msg)
    local followers = getFollowers(State.Events, State.Owner)
    for _, follower in ipairs(followers) do
        ao.send({
            Target = follower,
            Action = "Event",
            Data = msg.Data,
            Tags = msg.Tags
        })
    end
end

local function routeInternal(msg)
    if msg.Kind == Kinds.DELETE then
        State.Events = utils.filter(function(e) return e.Id ~= msg.Id end, State.Events)
    else
        table.insert(State.Events, msg)
    end
end

-- Main Protocol Handler
function event(msg)
    local myFollowList = getFollowList(State.Events, State.Owner)
    local isFollowing = utils.includes(msg.From, myFollowList)

    -- Always accept Kind 3 if this hub is explicitly listed
    if msg.Kind == Kinds.FOLLOW then
        for _, tag in ipairs(msg.Tags or {}) do
            if tag[1] == "p" and tag[2] == State.Owner then
                table.insert(State.Events, msg)
                break
            end
        end
        return
    end

    -- Messages from this hub (self)
    if msg.From == State.Owner then
        broadcastToFollowers(msg)
        routeInternal(msg)
        return
    end

    -- Accept these kinds from followed hubs
    local allowedKinds = {
        [Kinds.NOTE] = true,
        [Kinds.WRAPPED_SEAL] = true,
        [Kinds.PROFILE_UPDATE] = true,
        [Kinds.GOSSIP] = true
    }

    if isFollowing and allowedKinds[msg.Kind] then
        table.insert(State.Events, msg)

        -- Gossip if it's NOT a gossip message and hasn't been seen
        if msg.Kind ~= Kinds.GOSSIP and msg.Signature and not hasSeenReference(msg.Signature) then
            local gossipMsg = {
                Kind = Kinds.GOSSIP,
                Tags = {
                    { "hub", "true" },
                    { "received-from", msg.From },
                    { "reference-signature", msg.Signature },
                    { "referenced-kind", msg.Kind }
                },
                Data = "Gossip propagation for kind " .. msg.Kind
            }

            table.insert(State.Events, gossipMsg)

            local followers = getFollowers(State.Events, State.Owner)
            for _, follower in ipairs(followers) do
                ao.send({
                    Target = follower,
                    Action = "Event",
                    Data = gossipMsg.Data,
                    Tags = gossipMsg.Tags
                })
            end
        end
    end
end

-- Handlers
Handlers.add('Event', Handlers.utils.hasMatchingTag('Action', 'Event'), event)

Handlers.add('DeleteEvents', Handlers.utils.hasMatchingTag('Action', 'DeleteEvents'), function(msg)
    if msg.From == State.Owner then State.Events = {} end
end)

Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode({
            User = State.Owner,
            spec = State.Spec,
            Followers = getFollowers(State.Events, State.Owner),
            Following = getFollowList(State.Events, State.Owner)
        })
    })
end)

table.insert(ao.authorities,"5btmdnmjWiFugymH7BepSig8cq1_zE-EQVumcXn0i_4")

function simulateGossipTest()
    print("\\n--- Running Gossip Simulation ---")

    State.Owner = "HubA"
    State.Events = {}

    -- Hub A follows Hub B
    table.insert(State.Events, {
        Kind = Kinds.FOLLOW,
        From = "HubA",
        Tags = {
            { "p", "HubB" }
        }
    })

    -- Hub C follows Hub A
    table.insert(State.Events, {
        Kind = Kinds.FOLLOW,
        From = "HubC",
        Tags = {
            { "p", "HubA" }
        }
    })

    -- Hub B sends a NOTE (should be accepted + gossiped to HubC)
    event({
        Kind = Kinds.NOTE,
        From = "HubB",
        Signature = "sig001",
        Tags = {},
        Data = "Note from Hub B"
    })

    -- Hub D sends a NOTE (should be ignored)
    event({
        Kind = Kinds.NOTE,
        From = "HubD",
        Signature = "sig002",
        Tags = {},
        Data = "Sneaky message from Hub D"
    })

    -- Hub B sends a GOSSIP (should be accepted but not gossiped again)
    event({
        Kind = Kinds.GOSSIP,
        From = "HubB",
        Signature = "sig003",
        Tags = {
            { "hub", "true" },
            { "received-from", "HubZ" },
            { "reference-signature", "sig999" },
            { "referenced-kind", "0" }
        },
        Data = "Hub B gossip"
    })

    -- Hub C sends a NOTE (should be ignored)
    event({
        Kind = Kinds.NOTE,
        From = "HubC",
        Signature = "sig004",
        Tags = {},
        Data = "Note from follower (should be ignored)"
    })

    -- Summary
    print("\\n--- Final Stored Events ---")
    for i, e in ipairs(State.Events) do
        print(i .. ": Kind=" .. e.Kind .. " From=" .. (e.From or "Unknown") .. " Data=" .. (e.Data or ""))
        if e.Kind == Kinds.GOSSIP then
            print("    ↳ GOSSIP: ref=" .. (getTag(e.Tags, "reference-signature") or "none"))
        end
    end
end
