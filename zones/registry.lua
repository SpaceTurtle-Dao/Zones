-- Initialize global variables
--local ao = require('ao')
local json = require('json');
local bint = require('.bint')(256)
local utils = require(".utils")

Variant = "0.0.1"
if not Events then Events = {} end

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

local function slice(tbl, start_idx, end_idx)
    local new_table = {}
    table.move(tbl, start_idx or 1, end_idx or #tbl, 1, new_table)
    return new_table
end

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
    if msg.Kind == "0" and msg.Content then
        Events = utils.filter(function(event)
            return msg.From ~= event.From
        end, Events)
        table.insert(Events, msg)
    end
end


Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), function(msg)
    fetchEvents(msg)
end)


Handlers.add('Event', Handlers.utils.hasMatchingTag('Action', 'Event'), function(msg)
    event(msg)
end)
