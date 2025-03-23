-- Initialize global variables
--local ao = require('ao')
local json = require('json');
local bint = require('.bint')(256)
local utils = require(".utils")

-- Utils helper functions
Utils = {
    add = function(a, b)
        return tostring(bint(a) + bint(b))
    end,
    subtract = function(a, b)
        return tostring(bint(a) - bint(b))
    end,
    toBalanceValue = function(a)
        return tostring(bint(a))
    end,
    toNumber = function(a)
        return tonumber(a)
    end
}

function Spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a, b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function some(arr, predicate)
    for i = 1, #arr do
        if predicate(arr[i]) then
            return true
        end
    end
    return false
end

function slice(tbl, start_idx, end_idx)
    local new_table = {}
    table.move(tbl, start_idx or 1, end_idx or #tbl, 1, new_table)
    return new_table
end

Variant = "0.0.1"
if not Events then Events = {} end

local function filter(filter, events)
    local _events = events
    table.sort(_events, function(a, b)
        return a.Timestamp > b.Timestamp
    end)
    if filter.limit and filter.limit < #events then
        _events = slice(events, 1, filter.limit)
    end

    if filter.ids then
        _events = utils.filter(function(event)
            return utils.includes(event.Id, filter.ids)
        end, _events)
    end

    if filter.authors then
        _events = utils.filter(function(event)
            return utils.includes(event.From, filter.authors)
        end, _events)
    end

    if filter.kinds then
        _events = utils.filter(function(event)
            return utils.includes(event.Kind, filter.kinds)
        end, _events)
    end

    if filter.since then
        _events = utils.filter(function(event)
            return event.Timestamp > filter.since
        end, _events)
    end

    if filter["until"] then
        _events = utils.filter(function(event)
            return event.Timestamp < filter["until"]
        end, _events)
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
    return _events
end

local function fetch(tbl, page, size)
    local start = (page - 1) * size + 1
    local endPage = page * size
    local result = {};
    for i = start, endPage do
        if tbl[i] then
            table.insert(result, tbl[i])
        else
            break
        end
    end
    return result;
end

local function fetchEvents(msg)
    local filters = json.decode(msg.Filters)
    local _events = Events
    for k, v in ipairs(filters) do
        _events = filter(v, _events)
    end
    ao.send({
        Target = msg.From,
        Data = json.encode(_events)
    })
end

local function event(msg)
    if msg.Kind == "7" and msg.Content and msg.e and msg.p then
        local _event = utils.find(
            function(event) return msg.From == event.From and msg.Kind == event.Kind and msg.e == event.e and
                msg.p == event.p end,
            Events
        )
        if _event then
            Events = utils.filter(function(event)
                return event.Id ~= _event.Id
            end, Events)
        else
            table.insert(Events, msg)
        end
    else
        table.insert(Events, msg)
    end
end


Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), function(msg)
    fetchEvents(msg)
end)


Handlers.add('Event', Handlers.utils.hasMatchingTag('Action', 'Event'), function(msg)
    event(msg)
end)

Handlers.add('DeleteEvents', Handlers.utils.hasMatchingTag('Action', 'DeleteEvents'), function(msg)
    Events = {}
end)
