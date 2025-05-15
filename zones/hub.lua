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
    DELETION = "5",
    WRAPPED_SEAL = "6",
    REACTION = "7",
    GOSSIP = "1000",
    TOMBSTONE = "9001"
}

-- ✅ Use named constants here
local tombstoneBroadcastKinds = {
    [Kinds.PROFILE_UPDATE] = true,
    [Kinds.NOTE] = true,
    [Kinds.WRAPPED_SEAL] = true,
    [Kinds.REACTION] = true
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

function slice(tbl, start_idx, end_idx)
    local new_table = {}
    table.move(tbl, start_idx or 1, end_idx or #tbl, 1, new_table)
    return new_table
end

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
    local followEvents = utils.filter(function(e)
        return e.Kind == Kinds.FOLLOW and e.From == from
    end, events)

    if #followEvents == 0 then return {} end

    local latest = followEvents[#followEvents]
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

-- Client-side filtering
local function filter(filter, events)
    local _events = events

    if filter.ids then
        _events = utils.filter(function(e) return utils.includes(e.Id, filter.ids) end, _events)
    end

    if filter.authors then
        _events = utils.filter(function(e) return utils.includes(e.From, filter.authors) end, _events)
    end

    if filter.kinds then
        _events = utils.filter(function(e) return utils.includes(e.Kind, filter.kinds) end, _events)
    end

    if filter.since then
        _events = utils.filter(function(e) return e.Timestamp > filter.since end, _events)
    end

    if filter["until"] then
        _events = utils.filter(function(e) return e.Timestamp < filter["until"] end, _events)
    end

    if filter.tags then
        for tagKey, expectedValues in pairs(filter.tags) do
            _events = utils.filter(function(e)
                for _, tag in ipairs(e.Tags or {}) do
                    if tag[1] == tagKey and utils.includes(tag[2], expectedValues) then
                        return true
                    end
                end
                return false
            end, _events)
        end
    end

    if filter.search then
        _events = utils.filter(function(e)
            if e.Kind ~= Kinds.GOSSIP then return false end
            for _, tag in ipairs(e.Tags or {}) do
                if string.find(string.lower(tag[2] or ""), string.lower(filter.search)) then
                    return true
                end
            end
            return false
        end, _events)
    end

    table.sort(_events, function(a, b) return a.Timestamp > b.Timestamp end)

    local limit = math.min(filter.limit or 50, 500)
    if #_events > limit then
        _events = slice(_events, 1, limit)
    end

    return _events
end

local function fetchEvents(msg)
    local filters = json.decode(msg.Filters or "[]")
    local result = State.Events

    for _, f in ipairs(filters) do
        result = filter(f, result)
    end

    ao.send({
        Target = msg.From,
        Data = json.encode(result)
    })
end

-- Main Event Handler
function event(msg)
    local myFollowList = getFollowList(State.Events, State.Owner)
    local isFollowing = utils.includes(msg.From, myFollowList)

    if msg.Kind == Kinds.FOLLOW then
        local newFollowList = {}
        for _, tag in ipairs(msg.Tags or {}) do
            if tag[1] == "p" then
                table.insert(newFollowList, tag[2])
            end
        end

        local isFollowingMe = utils.includes(State.Owner, newFollowList)

        -- If this hub is no longer being followed, remove old follow list from sender
        if not isFollowingMe then
            State.Events = utils.filter(function(e)
                return not (e.Kind == Kinds.FOLLOW and e.From == msg.From)
            end, State.Events)
            return
        end

        -- Accept and store the follow list
        table.insert(State.Events, msg)
        return
    end

    if msg.Kind == Kinds.DELETION then
        for _, tag in ipairs(msg.Tags or {}) do
            local tagType, targetId = tag[1], tag[2]
            if (tagType == "e" or tagType == "a") then
                local kindToDelete = getTag(msg.Tags, "k")
                local tombstone = nil

                State.Events = utils.filter(function(e)
                    local match = e.Id == targetId and e.From == msg.From
                    if match then
                        tombstone = {
                            Kind = Kinds.TOMBSTONE,
                            Tags = {
                                { "deleted-id",     e.Id },
                                { "deleted-kind",   e.Kind },
                                { "deleted-by",     msg.From },
                                { "deleted-author", e.From }
                            },
                            Data = msg.Content or "",
                            Timestamp = msg.Timestamp or os.time()
                        }
                    end
                    return not match
                end, State.Events)

                if tombstone then
                    table.insert(State.Events, tombstone)

                    if tombstoneBroadcastKinds[tombstone.Tags[2][2]] then
                        broadcastToFollowers(tombstone)
                    end
                end
            end
        end

        table.insert(State.Events, msg)
        return
    end

    if msg.From == State.Owner then
        broadcastToFollowers(msg)
        table.insert(State.Events, msg)
        return
    end

    local allowedKinds = {
        [Kinds.NOTE] = true,
        [Kinds.WRAPPED_SEAL] = true,
        [Kinds.PROFILE_UPDATE] = true,
        [Kinds.GOSSIP] = true,
        [Kinds.REACTION] = true
    }

    if allowedKinds[msg.Kind] then
        local shouldGossip = isFollowing
            and msg.Kind ~= Kinds.GOSSIP
            and msg.Signature
            and not hasSeenReference(msg.Signature)

        table.insert(State.Events, msg)

        if shouldGossip then
            local gossipTags = {
                { "hub",                 "true" },
                { "received-from",       msg.From },
                { "reference-signature", msg.Signature },
                { "referenced-kind",     msg.Kind },
                { "Kind",                Kinds.GOSSIP }
            }

            for _, tag in ipairs(msg.Tags or {}) do
                table.insert(gossipTags, tag)
            end

            local gossipMsg = {
                Kind = Kinds.GOSSIP,
                Tags = gossipTags,
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
Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), fetchEvents)
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
