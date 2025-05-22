local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")

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

State = {
    Events = Events or {},
    Owner = Owner,
    Spec = {
        type = "hub",
        description = "Social message hub",
        version = "0.1",
        processId = ao.id
    }
}

State.FeePolicy = State.FeePolicy or {
    base = {
        [Kinds.NOTE] = 5000,
        [Kinds.WRAPPED_SEAL] = 10000,
        [Kinds.PROFILE_UPDATE] = 10000,
        [Kinds.REACTION] = 2000
    },
    scaleFactor = 1000,
    spikeEnabled = true,
    spikeWindow = 60,
    spikeScale = 60
}

State.AllowedKinds = State.AllowedKinds or {
    [Kinds.NOTE] = true,
    [Kinds.WRAPPED_SEAL] = true,
    [Kinds.PROFILE_UPDATE] = true,
    [Kinds.GOSSIP] = true,
    [Kinds.REACTION] = true
}

local tombstoneBroadcastKinds = {
    [Kinds.PROFILE_UPDATE] = true,
    [Kinds.NOTE] = true,
    [Kinds.WRAPPED_SEAL] = true,
    [Kinds.REACTION] = true
}

local RecentActivity = {}

local function slice(tbl, start_idx, end_idx)
    local new_table = {}
    table.move(tbl, start_idx or 1, end_idx or #tbl, 1, new_table)
    return new_table
end

local function getTag(tags, key)
    for _, tag in ipairs(tags or {}) do
        if tag[1] == key then return tag[2] end
    end
end

local function hasSeenReference(sig)
    for _, e in ipairs(State.Events) do
        if e.Kind == Kinds.GOSSIP and getTag(e.Tags, "reference-signature") == sig then
            return true
        end
    end
end

local function getFollowList(events, from)
    for i = #events, 1, -1 do
        local e = events[i]
        if e.Kind == Kinds.FOLLOW and e.From == from then
            local list = {}
            for _, tag in ipairs(e.Tags or {}) do
                if tag[1] == "p" then table.insert(list, tag[2]) end
            end
            return list
        end
    end
    return {}
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
    for _, f in ipairs(getFollowers(State.Events, ao.id)) do
        ao.send({ Target = f, Action = "Event", Data = msg.Data, Tags = msg.Tags })
    end
end

local function calculateDynamicFee(kind, from)
    if from == State.Owner then return 0 end
    local myFollowList = getFollowList(State.Events, ao.id)
    local isFollowing = utils.includes(from, myFollowList)
    local base = State.FeePolicy.base[kind] or 0
    if isFollowing then return 0 end
    local volumeFactor = #State.Events / (State.FeePolicy.scaleFactor or 1000)

    local spikeFactor = 0
    if State.FeePolicy.spikeEnabled then
        local now = os.time()
        local window = State.FeePolicy.spikeWindow or 60
        local scale = State.FeePolicy.spikeScale or 60

        RecentActivity = utils.filter(function(ts)
            return ts > now - window
        end, RecentActivity)

        spikeFactor = #RecentActivity / scale
    end

    local multiplier = 1 + volumeFactor + spikeFactor
    return base * multiplier
end

local function deleteRequest(msg)
    if msg.Kind == Kinds.DELETION then
        for _, tag in ipairs(msg.Tags or {}) do
            if tag[1] == "e" or tag[1] == "a" then
                local tombstone = nil
                State.Events = utils.filter(function(e)
                    local match = e.Id == tag[2] and e.From == msg.From
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
end

local function gossip(msg)
    if State.AllowedKinds[msg.Kind] then
        local shouldGossip = isFollowing and msg.Kind ~= Kinds.GOSSIP and msg.Signature and
            not hasSeenReference(msg.Signature)
        table.insert(State.Events, msg)
        if shouldGossip then
            local tags = {
                { "hub",                 "true" },
                { "received-from",       msg.From },
                { "reference-signature", msg.Signature },
                { "referenced-kind",     msg.Kind },
                { "Kind",                Kinds.GOSSIP }
            }
            for _, tag in ipairs(msg.Tags or {}) do table.insert(tags, tag) end
            local gossipMsg = {
                Kind = Kinds.GOSSIP,
                Tags = tags,
                Data = "Gossip propagation for kind " .. msg.Kind
            }
            table.insert(State.Events, gossipMsg)
            broadcastToFollowers(gossipMsg)
        end
    end
end

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
        for key, tags in pairs(filter.tags) do
            _events = utils.filter(function(e)
                if e[key] then
                    return utils.includes(e[key], tags)
                end
                return false
            end, events)
        end
    end

    if filter.search then
        _events = utils.filter(function(e)
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

function event(msg)
    table.insert(RecentActivity, os.time())

    local myFollowList = getFollowList(State.Events, ao.id)
    local isFollowing = utils.includes(msg.From, myFollowList)

    if msg.Kind == Kinds.FOLLOW then
        local newFollowList = {}
        for _, tag in ipairs(msg.Tags or {}) do
            if tag[1] == "p" then
                table.insert(newFollowList, tag[2])
            end
        end
        local isFollowingMe = utils.includes(ao.id, newFollowList)
        if not isFollowingMe then
            State.Events = utils.filter(function(e)
                return not (e.Kind == Kinds.FOLLOW and e.From == msg.From)
            end, State.Events)
            return
        end
        table.insert(State.Events, msg)
        return
    end

    deleteRequest(msg)

    gossip(msg)

    if msg.From == ao.id then
        table.insert(State.Events, msg)
        broadcastToFollowers(msg)
        return
    end
end



Handlers.add("Event", function(msg)
    local following = getFollowList(State.Events, ao.id)
    local isFollowed = utils.includes(msg.From, following)
    if msg.From == State.Owner then
        msg.From = ao.id
        event(msg)
    end
    if isFollowed or msg.Kind == "3" then
        event(msg)
    end
end)

Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag("Action", "Credit-Notice"), function(msg)
    local from = msg.From
    local payloadStr = msg["X-Payload"]
    local amount = tonumber(msg.Amount or "0")
    if not payloadStr then return end
    local ok, payload = pcall(json.decode, payloadStr)
    if not ok or type(payload) ~= "table" then return end
    local kind = payload.Kind or getTag(payload.Tags, "kind")
    if not kind then return end
    local required = calculateDynamicFee(kind, from)
    if amount < required then return end
    payload.Tags = payload.Tags or {}
    table.insert(payload.Tags, { "paid", "true" })
    table.insert(payload.Tags, { "paid-amount", tostring(amount) })
    table.insert(payload.Tags, { "required-fee", tostring(required) })
    event(payload)
end)

Handlers.add("QueryFee", Handlers.utils.hasMatchingTag("Action", "QueryFee"), function(msg)
    if not msg.Kind then return end
    local fee = calculateDynamicFee(msg.Kind, msg.From)
    ao.send({ Target = msg.From, Data = json.encode({ kind = msg.Kind, requiredFee = fee }) })
end)

Handlers.add("Config", Handlers.utils.hasMatchingTag("Action", "Config"), function(msg)
    if msg.From ~= State.Owner then return end
    local ok, body = pcall(json.decode, msg.Data or "{}")
    if not ok or type(body) ~= "table" then return end

    if body.FeePolicy then
        State.FeePolicy = body.FeePolicy
    end

    if body.AllowedKinds then
        State.AllowedKinds = body.AllowedKinds
    end
end)

Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), fetchEvents)

Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode({
            User = State.Owner,
            Spec = State.Spec,
            FeePolicy = State.FeePolicy,
            AllowedKinds = State.AllowedKinds,
            Followers = getFollowers(State.Events, ao.id),
            Following = getFollowList(State.Events, ao.id)
        })
    })
end)

table.insert(ao.authorities, "5btmdnmjWiFugymH7BepSig8cq1_zE-EQVumcXn0i_4")