local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")

-- Velocity Protocol VIP Message Kinds
Kinds = {
    PROFILE_UPDATE = "0",
    NOTE = "1",
    REPLY = "1", 
    FOLLOW = "3",
    REACTION = "7"
}

-- Open Hub State - Public Velocity Protocol Hub
State = {
    Events = Events or {},
    Owner = Owner or ao.id,
    Spec = {
        type = "hub",
        description = "Open Public Velocity Protocol Hub - Censorship-resistant messaging",
        version = "1.0",
        processId = ao.id,
        kinds = {1, 3, 7}, -- VIP-03: text/replies, VIP-02: follows, VIP-04: reactions
        supportedProtocols = {"velocity"},
        isPublic = true,
        acceptsAllEvents = true
    },
    -- VIP-07: Security configurations
    Security = {
        bannedAuthors = {},
        trustedAuthors = {},
        spamFilters = true
    },
    -- VIP-06: Hub registration data
    Registration = {
        registry = "qrXGWjZ1qYkFK4_rCHwwKKEtgAE3LT0WJ-MYhpaMjtE", -- Default registry
        lastRegistered = 0,
        registrationInterval = 3600000, -- 1 hour
        autoRegister = true
    },
    -- VIP-02: Social graph tracking
    FollowGraph = {
        followers = {},
        following = {}
    },
    -- Performance indexes for fast lookups
    Indexes = {
        byAuthor = {}, -- author -> array of event IDs
        byId = {},     -- event ID -> event
        byKind = {},   -- kind -> array of event IDs
        byTag = {}     -- tag -> array of event IDs
    },
    -- Simple analytics counters
    Stats = {
        totalEvents = 0,
        eventsByKind = {},
        uniqueAuthors = {},
        lastUpdated = 0
    }
}

-- Utility functions
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

local function addUniqueString(array, hashTable, str)
    if not hashTable[str] then
        hashTable[str] = true
        table.insert(array, str)
    end
end

-- Index management functions
local function addToIndex(event)
    local eventId = event.Id or event.Original_Id
    if not eventId then return end
    
    -- Index by ID
    State.Indexes.byId[eventId] = event
    
    -- Index by author
    if event.From then
        if not State.Indexes.byAuthor[event.From] then
            State.Indexes.byAuthor[event.From] = {}
        end
        table.insert(State.Indexes.byAuthor[event.From], eventId)
    end
    
    -- Index by kind
    if event.Kind then
        if not State.Indexes.byKind[event.Kind] then
            State.Indexes.byKind[event.Kind] = {}
        end
        table.insert(State.Indexes.byKind[event.Kind], eventId)
    end
    
    -- Index by tags
    if event.Tags then
        for _, tag in ipairs(event.Tags) do
            local tagKey = tag[1]
            if tagKey then
                if not State.Indexes.byTag[tagKey] then
                    State.Indexes.byTag[tagKey] = {}
                end
                table.insert(State.Indexes.byTag[tagKey], eventId)
            end
        end
    end
    
    -- Update stats
    State.Stats.totalEvents = State.Stats.totalEvents + 1
    if event.Kind then
        State.Stats.eventsByKind[event.Kind] = (State.Stats.eventsByKind[event.Kind] or 0) + 1
    end
    if event.From then
        State.Stats.uniqueAuthors[event.From] = true
    end
    State.Stats.lastUpdated = tonumber(ao.env.Process.Timestamp) or 0
end

local function removeFromIndex(event)
    local eventId = event.Id or event.Original_Id
    if not eventId then return end
    
    -- Remove from ID index
    State.Indexes.byId[eventId] = nil
    
    -- Remove from author index
    if event.From and State.Indexes.byAuthor[event.From] then
        State.Indexes.byAuthor[event.From] = utils.filter(
            function(id) return id ~= eventId end,
            State.Indexes.byAuthor[event.From]
        )
    end
    
    -- Remove from kind index
    if event.Kind and State.Indexes.byKind[event.Kind] then
        State.Indexes.byKind[event.Kind] = utils.filter(
            function(id) return id ~= eventId end,
            State.Indexes.byKind[event.Kind]
        )
    end
end

-- VIP-07: Enhanced message validation
local function validateMessage(msg)
    -- Basic required fields
    if not msg.From then
        return false, "Missing required field: From"
    end
    
    if not msg.Kind then
        return false, "Missing required field: Kind"
    end
    
    -- Check if author is banned
    if State.Security.bannedAuthors[msg.From] then
        return false, "Author '" .. msg.From .. "' is banned from this hub"
    end
    
    -- Validate required fields based on VIP specifications
    if msg.Kind == Kinds.NOTE or msg.Kind == "1" then
        if not msg.Content then
            return false, "VIP-03: Note messages must include Content field"
        end
        if msg.marker == "reply" then
            if not msg.e then
                return false, "VIP-03: Reply messages must include 'e' field (target event ID)"
            end
            if not msg.p then
                return false, "VIP-03: Reply messages must include 'p' field (target author)"
            end
        end
    elseif msg.Kind == Kinds.REACTION or msg.Kind == "7" then
        if not msg.Content then
            return false, "VIP-04: Reaction messages must include Content field"
        end
        if not msg.e then
            return false, "VIP-04: Reaction messages must include 'e' field (target event ID)"
        end
        if not msg.p then
            return false, "VIP-04: Reaction messages must include 'p' field (target author)"
        end
    elseif msg.Kind == Kinds.FOLLOW or msg.Kind == "3" then
        if not msg.p then
            return false, "VIP-02: Follow messages must include 'p' field (follow list)"
        end
        -- Validate follow list is valid JSON
        local success, followList = pcall(json.decode, msg.p)
        if not success then
            return false, "VIP-02: Follow list 'p' field must be valid JSON array"
        end
        if type(followList) ~= "table" then
            return false, "VIP-02: Follow list must be an array"
        end
    end
    
    return true, "Message validation passed"
end

-- VIP-01: Enhanced ANS-104 message validation
local function validateANS104(msg)
    -- Basic ANS-104 validation
    if not msg.From then
        return false, "ANS-104: Missing 'From' field (author address)"
    end
    
    if not msg.Id then
        return false, "ANS-104: Missing 'Id' field (message ID)"
    end
    
    if not msg.Timestamp then
        return false, "ANS-104: Missing 'Timestamp' field"
    end
    
    -- Validate timestamp is reasonable (within last year and not future)
    local currentTime = tonumber(ao.env.Process.Timestamp) or 0
    local oneYear = 365 * 24 * 60 * 60 * 1000 -- milliseconds
    
    if msg.Timestamp > currentTime + 300000 then -- 5 minutes tolerance
        return false, "ANS-104: Timestamp is too far in the future"
    end
    
    if msg.Timestamp < currentTime - oneYear then
        return false, "ANS-104: Timestamp is too old (more than 1 year)"
    end
    
    -- Verify signature if present
    if msg.Signature then
        -- Basic signature presence check (actual verification would require crypto libs)
        if type(msg.Signature) ~= "string" or #msg.Signature == 0 then
            return false, "ANS-104: Invalid signature format"
        end
    end
    
    return true, "ANS-104 validation passed"
end

-- VIP-02: Follow list management
local function getFollowList(author)
    author = author or ao.id
    for i = #State.Events, 1, -1 do
        local e = State.Events[i]
        if e.Kind == Kinds.FOLLOW and e.From == author then
            return json.decode(e.p or "[]")
        end
    end
    return {}
end

local function getFollowers()
    local followers = {}
    local followers_hash = {}
    for i = #State.Events, 1, -1 do
        local e = State.Events[i]
        if e.Kind == Kinds.FOLLOW and e.From ~= ao.id then
            local followList = json.decode(e.p or "[]")
            if utils.includes(ao.id, followList) then
                addUniqueString(followers, followers_hash, e.From)
            end
        end
    end
    return followers
end

-- VIP-04: Reaction deduplication (enhanced with indexing)
local function handleReaction(msg)
    -- Use author index for faster lookup
    local authorEvents = State.Indexes.byAuthor[msg.From] or {}
    local existingReaction = nil
    
    for _, eventId in ipairs(authorEvents) do
        local event = State.Indexes.byId[eventId]
        if event and event.Kind == msg.Kind and event.e == msg.e and event.p == msg.p then
            existingReaction = event
            break
        end
    end
    
    if existingReaction then
        -- Remove existing reaction (toggle behavior)
        removeFromIndex(existingReaction)
        State.Events = utils.filter(function(event)
            return event.Id ~= existingReaction.Id
        end, State.Events)
        return false -- Reaction removed
    else
        -- Add new reaction
        table.insert(State.Events, msg)
        addToIndex(msg)
        return true -- Reaction added
    end
end

-- VIP-03: Reply handling (enhanced with indexing)
local function handleReply(msg)
    if msg.marker == "reply" and msg.e and msg.p then
        -- Use author index for faster lookup
        local authorEvents = State.Indexes.byAuthor[msg.From] or {}
        local existingReply = nil
        
        for _, eventId in ipairs(authorEvents) do
            local event = State.Indexes.byId[eventId]
            if event and event.Kind == msg.Kind and event.e == msg.e and 
               event.p == msg.p and event.marker == "reply" then
                existingReply = event
                break
            end
        end
        
        if existingReply then
            -- Replace existing reply
            removeFromIndex(existingReply)
            State.Events = utils.filter(function(event)
                return event.Id ~= existingReply.Id
            end, State.Events)
        end
        
        table.insert(State.Events, msg)
        addToIndex(msg)
        return true
    end
    return false
end

-- VIP-02: Follow event processing (enhanced with indexing)
local function handleFollow(msg)
    local followList = json.decode(msg.p or "[]")
    local wasFollowing = utils.includes(ao.id, getFollowList(msg.From))
    local isFollowing = utils.includes(ao.id, followList)
    
    -- Remove existing follow events from this author
    local authorEvents = State.Indexes.byAuthor[msg.From] or {}
    for _, eventId in ipairs(authorEvents) do
        local event = State.Indexes.byId[eventId]
        if event and event.Kind == Kinds.FOLLOW then
            removeFromIndex(event)
            State.Events = utils.filter(function(e)
                return e.Id ~= event.Id
            end, State.Events)
            break
        end
    end
    
    if #followList > 0 then
        table.insert(State.Events, msg)
        addToIndex(msg)
    end
    
    -- Notify followed/unfollowed users
    if not wasFollowing and isFollowing then
        ao.send({ Target = msg.From, Action = "FollowNotification", Type = "followed" })
    elseif wasFollowing and not isFollowing then
        ao.send({ Target = msg.From, Action = "FollowNotification", Type = "unfollowed" })
    end
end

-- Broadcast events to followers
local function broadcastToFollowers(msg)
    local followers = getFollowers()
    for _, follower in ipairs(followers) do
        ao.send({ 
            Target = follower, 
            Action = "Event", 
            Data = msg.Data, 
            Tags = msg.Tags,
            Kind = msg.Kind,
            From = msg.From
        })
    end
end

-- VIP-01: Event filtering per protocol specification (enhanced with indexes)
local function filter(filterParams, events)
    local _events = {}
    
    -- Use indexes for faster filtering when possible
    if filterParams.ids then
        for _, id in ipairs(filterParams.ids) do
            local event = State.Indexes.byId[id]
            if event then
                table.insert(_events, event)
            end
        end
    elseif filterParams.authors and #filterParams.authors == 1 then
        -- Single author optimization
        local author = filterParams.authors[1]
        local authorEventIds = State.Indexes.byAuthor[author] or {}
        for _, eventId in ipairs(authorEventIds) do
            local event = State.Indexes.byId[eventId]
            if event then
                table.insert(_events, event)
            end
        end
    elseif filterParams.kinds and #filterParams.kinds == 1 then
        -- Single kind optimization
        local kind = filterParams.kinds[1]
        local kindEventIds = State.Indexes.byKind[kind] or {}
        for _, eventId in ipairs(kindEventIds) do
            local event = State.Indexes.byId[eventId]
            if event then
                table.insert(_events, event)
            end
        end
    else
        -- Fall back to full scan for complex queries
        _events = events
    end
    
    -- Apply remaining filters
    if filterParams.authors and #filterParams.authors > 1 then
        _events = utils.filter(function(e) 
            return utils.includes(e.From, filterParams.authors) 
        end, _events)
    end
    
    if filterParams.kinds and #filterParams.kinds > 1 then
        _events = utils.filter(function(e) 
            return utils.includes(e.Kind, filterParams.kinds) 
        end, _events)
    end
    
    if filterParams.since then
        _events = utils.filter(function(e) 
            return e.Timestamp > filterParams.since 
        end, _events)
    end
    
    if filterParams["until"] then
        _events = utils.filter(function(e) 
            return e.Timestamp < filterParams["until"] 
        end, _events)
    end
    
    if filterParams.tags then
        for key, tags in pairs(filterParams.tags) do
            _events = utils.filter(function(e)
                local tagValue = getTag(e.Tags, key)
                return tagValue and utils.includes(tagValue, tags)
            end, _events)
        end
    end
    
    if filterParams.search then
        local searchText = string.lower(filterParams.search)
        _events = utils.filter(function(e)
            -- Search in content
            if e.Content and string.find(string.lower(e.Content), searchText, 1, true) then
                return true
            end
            -- Search in tags
            for _, tag in ipairs(e.Tags or {}) do
                if tag[2] and string.find(string.lower(tag[2]), searchText, 1, true) then
                    return true
                end
            end
            -- Search in author (partial match)
            if e.From and string.find(string.lower(e.From), searchText, 1, true) then
                return true
            end
            return false
        end, _events)
    end
    
    -- Sort by timestamp (newest first)
    table.sort(_events, function(a, b) return a.Timestamp > b.Timestamp end)
    
    -- Apply limit
    local limit = math.min(filterParams.limit or 100, 1000)
    if #_events > limit then
        _events = slice(_events, 1, limit)
    end
    
    return _events
end

-- VIP-01: FetchEvents handler
local function fetchEvents(msg)
    local filters = json.decode(msg.Filters or "[]")
    local result = State.Events
    
    for _, f in ipairs(filters) do
        result = filter(f, result)
    end
    
    ao.send({
        Target = msg.From,
        Action = "EventsResponse",
        Data = json.encode(result)
    })
end

-- Main event processing function
function processEvent(msg)
    -- VIP-07: Validate message
    local isValid, errorMsg = validateMessage(msg)
    if not isValid then
        ao.send({
            Target = msg.From,
            Action = "ValidationError",
            Data = json.encode({
                error = "Message validation failed",
                details = errorMsg,
                messageId = msg.Id,
                timestamp = tonumber(ao.env.Process.Timestamp) or 0
            }),
            Tags = {
                {"Error-Type", "Validation"},
                {"Error-Code", "VIP-07"}
            }
        })
        return
    end
    
    -- VIP-01: Validate ANS-104 format
    local isValidANS104, ans104Error = validateANS104(msg)
    if not isValidANS104 then
        ao.send({
            Target = msg.From,
            Action = "ValidationError",
            Data = json.encode({
                error = "ANS-104 validation failed",
                details = ans104Error,
                messageId = msg.Id,
                timestamp = tonumber(ao.env.Process.Timestamp) or 0
            }),
            Tags = {
                {"Error-Type", "ANS-104"},
                {"Error-Code", "VIP-01"}
            }
        })
        return
    end
    
    -- Process based on message kind
    if msg.Kind == Kinds.FOLLOW then
        handleFollow(msg)
    elseif msg.Kind == Kinds.REACTION then
        handleReaction(msg)
        broadcastToFollowers(msg)
    elseif msg.Kind == Kinds.NOTE then
        if msg.marker == "reply" then
            handleReply(msg)
        else
            table.insert(State.Events, msg)
            addToIndex(msg)
        end
        broadcastToFollowers(msg)
    else
        -- Handle other kinds
        table.insert(State.Events, msg)
        addToIndex(msg)
        broadcastToFollowers(msg)
    end
    
    -- Events persist forever (Arweave permanence principle)
end

-- VIP-06: Auto-registration with registry
local function registerWithRegistry()
    if State.Registration.autoRegister and State.Registration.registry then
        local currentTime = tonumber(ao.env.Process.Timestamp) or 0
        if currentTime - State.Registration.lastRegistered > State.Registration.registrationInterval then
            ao.send({
                Target = State.Registration.registry,
                Action = "Register",
                Data = json.encode(State.Spec),
                Tags = {
                    {"Data-Protocol", "Zone"},
                    {"Zone-Type", "Channel"}
                }
            })
            State.Registration.lastRegistered = currentTime
        end
    end
end

-- Handlers

-- VIP-01: Event handler
Handlers.add('Event', Handlers.utils.hasMatchingTag('Action', 'Event'), processEvent)

-- VIP-01: FetchEvents handler  
Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), fetchEvents)

-- Info handler for hub discovery
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode({
            User = State.Owner,
            Spec = State.Spec,
            Security = {
                spamFilters = State.Security.spamFilters
            },
            Stats = {
                totalEvents = State.Stats.totalEvents,
                eventsByKind = State.Stats.eventsByKind,
                uniqueAuthors = #utils.keys(State.Stats.uniqueAuthors),
                followers = #getFollowers(),
                following = #getFollowList(),
                lastUpdated = State.Stats.lastUpdated
            }
        })
    })
end)

-- VIP-06: Registration handler
Handlers.add("Register", Handlers.utils.hasMatchingTag("Action", "Register"), function(msg)
    if msg.Registry then
        State.Registration.registry = msg.Registry
        registerWithRegistry()
        ao.send({
            Target = msg.From,
            Data = "Hub registration updated"
        })
    end
end)

-- Health check handler
Handlers.add("Health", Handlers.utils.hasMatchingTag("Action", "Health"), function(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode({
            status = "healthy",
            uptime = tonumber(ao.env.Process.Timestamp) or 0,
            eventsCount = #State.Events,
            spec = State.Spec
        })
    })
end)

-- Periodic auto-registration
Handlers.add("Cron", Handlers.utils.hasMatchingTag("Action", "Cron"), function(msg)
    registerWithRegistry()
end)

-- Initialize the hub
print("Velocity Protocol Open Hub initialized")
print("Process ID: " .. ao.id)
print("Supported Kinds: " .. json.encode(State.Spec.kinds))
print("Public Hub: " .. tostring(State.Spec.isPublic))