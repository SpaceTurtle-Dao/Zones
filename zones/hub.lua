local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")

Kinds = {
    PROFILE_UPDATE = "0",
    NOTE = "1",
    FOLLOW = "3",
    REACTION = "7"
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

local function getFollowList()
    for i = #State.Events, 1, -1 do
        local e = State.Events[i]
        if e.Kind == Kinds.FOLLOW and e.From == ao.id then
            return json.decode(e.p)
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
            addUniqueString(followers, followers_hash, e.From)
        end
    end
    return followers
end

function compareFollowLists(msg)
    if msg.Kind ~= Kinds.FOLLOW then return nil end
  
    local oldList = {}
    for i = #State.Events, 1, -1 do
      local e = State.Events[i]
      if e.Kind == Kinds.FOLLOW and e.From == msg.From then
        for _, tag in ipairs(e.Tags or {}) do
          if tag[1] == "p" then table.insert(oldList, tag[2]) end
        end
        break
      end
    end
  
    local newList = {}
    for _, tag in ipairs(msg.Tags or {}) do
      if tag[1] == "p" then table.insert(newList, tag[2]) end
    end
  
    -- Convert to sets
    local oldSet, newSet = {}, {}
    for _, v in ipairs(oldList) do oldSet[v] = true end
    for _, v in ipairs(newList) do newSet[v] = true end
  
    -- Compute additions and deletions
    local additions, deletions = {}, {}
  
    for _, v in ipairs(newList) do
      if not oldSet[v] then table.insert(additions, v) end
    end
  
    for _, v in ipairs(oldList) do
      if not newSet[v] then table.insert(deletions, v) end
    end
  
    return {
      additions = additions,
      deletions = deletions
    }
  end
  

local function broadcastToFollowers(msg)
    for _, f in ipairs(getFollowers()) do
        ao.send({ Target = f, Action = "Event", Data = msg.Data, Tags = msg.Tags })
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
    local following = getFollowList()
    local isFollowed = utils.includes(msg.From, following)

    if msg.From == State.Owner then
        msg.From = ao.id
        if msg.Kind == Kinds.FOLLOW then
            for _, v in ipairs(json.decode(msg.p)) do
                ao.send({ Target = v, Action = "Event", p = msg.p, Kind = msg.Kind })
            end
            --[[local result = compareFollowLists(msg)
            for _, v in ipairs(result.additions) do
                ao.send({ Target = v, Action = "Event", Tags = msg.Tags })
            end
            for _, v in ipairs(result.deletions) do
                ao.send({ Target = v, Action = "Event", Tags = msg.Tags })
            end]]--            
        end
        table.insert(State.Events, msg)
        broadcastToFollowers(msg)
    elseif msg.Kind == Kinds.FOLLOW then
        local isFollowingMe = utils.includes(ao.id, json.decode(msg.p))
        if not isFollowingMe then
            State.Events = utils.filter(function(e)
                return not (e.Kind == Kinds.FOLLOW and e.From == msg.From)
            end, State.Events)
        else
            table.insert(State.Events, msg)
        end
    elseif isFollowed then
        table.insert(State.Events, msg)
    end
end

Handlers.add('Event', Handlers.utils.hasMatchingTag('Action', 'Event'), event)

Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), fetchEvents)

Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode({
            User = State.Owner,
            Spec = State.Spec,
            FeePolicy = State.FeePolicy,
            AllowedKinds = State.AllowedKinds,
            Followers = getFollowers(),
            Following = getFollowList()
        })
    })
end)

table.insert(ao.authorities, "5btmdnmjWiFugymH7BepSig8cq1_zE-EQVumcXn0i_4")