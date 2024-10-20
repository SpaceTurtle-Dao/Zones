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
Token = "WPyLgOqELOyN_BoTNdeEMZp5sz3RxDL19IGcs3A9IPc" -- AO or wAR token currently set to swappy tokens for testing
FeedCost = "1000000"
if not EventId then EventId = 1 end
if not Profile then Profile = {} end
if not SubscriptionRequest then SubscriptionRequest = {} end
if not Subscriptions then Subscriptions = {} end
if not Subs then Subs = {} end
if not Events then Events = {} end
if not Feed then Feed = {} end

local function info(msg)
    local data = {
        Process = ao.id,
        Token = Token,
        Events = tostring(EventId),
        Profile = Profile,
        FeedCost = FeedCost,
        Subs = #Subs,
        Subscriptions = #Subscriptions
    }
    ao.send({
        Target = msg.From,
        Data = json.encode(data)
    })
end

local function filter(filter, events)
    local _events = events
    table.sort(_events, function(a, b)
        return a.Timestamp > b.Timestamp
    end)
    if filter.limit and filter.limit < #events then
        _events = slice(0, filter.limit)
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

local function fetchFeed(msg)
    local filters = json.decode(msg.Filters)
    local _feed = Feed
    for k, v in ipairs(filters) do
        _feed = filter(v, _feed)
    end
    ao.send({
        Target = msg.From,
        Data = json.encode(_feed)
    })
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

local function fetchSubs(msg)
    local page = Utils.toNumber(msg.Page)
    local size = Utils.toNumber(msg.Size)
    ao.send({
        Target = msg.From,
        Data = json.encode(fetch(Subs, page, size))
    })
end

local function fetchSubscriptions(msg)
    local page = Utils.toNumber(msg.Page)
    local size = Utils.toNumber(msg.Size)
    ao.send({
        Target = msg.From,
        Data = json.encode(fetch(Subscriptions, page, size))
    })
end

local function feed(msg)
    local isSubscription = utils.includes(msg.From, Subscriptions)
    if isSubscription == false then return end
    table.insert(Feed, msg)
end

local function event(msg)
    if msg.From == Owner then
        local message = {
            Target = ao.id,
            Action = "Event",
            Data = msg.Data,
            Tags = msg.Tags
        }
        ao.send(message)
        return
    end
    if msg.Kind == "7" and msg.Content and msg.e and msg.p then
        local _event = utils.find(
            function(event) return msg.From == event.From and msg.Kind == event.Kind and msg.e == event.e and msg.p == event.p end,
            Events
        )
        if _event then
            Events = utils.filter(function(event)
                return event.Id ~= _event.Id
            end, Events)
        else
            table.insert(Events, msg)    
        end
    elseif msg.From == ao.id and msg.Kind == "0" and msg.Content then
        Events = utils.filter(function(event)
            return event.Kind ~= "0"
        end, Events)
        Profile = json.decode(msg.Content)
        table.insert(Events, msg)
    elseif msg.From == ao.id then
        if #Subs > 0 then
            for k, v in ipairs(Subs) do
                local message = {
                    Target = v,
                    Action = "Feed"
                }
                message["X-Id"] = msg.Id
                ao.send(message)
            end
        end
        table.insert(Events, msg)
    end
end

local function subscribe(msg)
    assert(Owner == msg.From)
    SubscriptionRequest[msg.Relay] = true
    ao.send({
        Target = msg.Relay,
        Action = "SubscriptionRequest"
    })
end

local function unsubscribe(msg)
    assert(Owner == msg.From)
    SubscriptionRequest[msg.Relay] = false
    ao.send({
        Target = msg.Relay,
        Action = "UnSubscribed"
    })
end

local function subscriptionRequest(msg)
    utils.filter(function(val) return val ~= msg.From end, Subs)
    table.insert(Subs, msg.From)
    ao.send({
        Target = msg.From,
        Action = "Subscribed",
    })
end

local function unsubscribed(msg)
    local temp = {}
    for k, v in ipairs(Subs) do
        if v ~= msg.From then
            table.insert(temp, v)
        end
    end
    Subs = temp
    ao.send({
        Target = msg.From,
        Action = "Subscribed",
    })
end

local function isSubscribed(msg)
    ao.send({
        Target = msg.From,
        Data = utils.includes(msg.Relay, Subscriptions),
    })
end

local function subscribed(msg)
    if SubscriptionRequest[msg.From] == true then
        --add to subscription list
        local temp = {}
        for k, v in ipairs(Subscriptions) do
            if v ~= msg.From then
                table.insert(temp, v)
            end
        end
        table.insert(temp, msg.From)
        Subscriptions = temp
    elseif SubscriptionRequest[msg.From] == false then
        --remove from subscription list
        local temp = {}
        for k, v in ipairs(Subscriptions) do
            if v ~= msg.From then
                table.insert(temp, v)
            end
        end
        Subscriptions = temp
    end
end


Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(msg)
    info(msg)
end)

Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), function(msg)
    fetchEvents(msg)
end)

Handlers.add('FetchFeed', Handlers.utils.hasMatchingTag('Action', 'FetchFeed'), function(msg)
    fetchFeed(msg)
end)

Handlers.add('Subs', Handlers.utils.hasMatchingTag('Action', 'Subs'), function(msg)
    fetchSubs(msg)
end)

Handlers.add('Subscriptions', Handlers.utils.hasMatchingTag('Action', 'Subscriptions'), function(msg)
    fetchSubscriptions(msg)
end)

Handlers.add('IsSubscribed', Handlers.utils.hasMatchingTag('Action', 'IsSubscribed'), function(msg)
    isSubscribed(msg)
end)

Handlers.add('Event', Handlers.utils.hasMatchingTag('Action', 'Event'), function(msg)
    event(msg)
end)

Handlers.add('Feed', Handlers.utils.hasMatchingTag('Action', 'Feed'), function(msg)
    feed(msg)
end)

Handlers.add('SubscriptionRequest', Handlers.utils.hasMatchingTag('Action', 'SubscriptionRequest'), function(msg)
    subscriptionRequest(msg)
end)

Handlers.add('Subscribe', Handlers.utils.hasMatchingTag('Action', 'Subscribe'), function(msg)
    subscribe(msg)
end)
Handlers.add('UnSubscribe', Handlers.utils.hasMatchingTag('Action', 'UnSubscribe'), function(msg)
    unsubscribe(msg)
end)

Handlers.add('Subscribed', Handlers.utils.hasMatchingTag('Action', 'Subscribed'), function(msg)
    subscribed(msg)
end)

Handlers.add('UnSubscribed', Handlers.utils.hasMatchingTag('Action', 'UnSubscribed'), function(msg)
    unsubscribed(msg)
end)

Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), function(msg)
    if msg.From ~= Token then
        --[[return funds and send message about unsupported token]] --
        ao.send({
            Target = msg.From,
            Quantity = msg.Quantity,
            Recipient = msg.Sender
        })
        return
    end
    if not msg["X-Type"] then
        ao.send({
            Target = msg.From,
            Quantity = msg.Quantity,
            Recipient = msg.Sender
        })
        return
    end

    if msg["X-Type"] == "PayedFeed" then
        payedFeed(msg)
        return
    end
    if msg["X-Type"] == "SubscriptionRequest" then
        subscriptionRequest(msg)
        return
    end
    ao.send({
        Target = msg.From,
        Quantity = msg.Quantity,
        Recipient = msg.Sender
    })
end)

Handlers.add('SetOwner', Handlers.utils.hasMatchingTag('Action', 'SetOwner'), function(msg)
    assert(msg.From == Owner)
    Owner = msg._Owner
end)

Handlers.add('GetOwner', Handlers.utils.hasMatchingTag('Action', 'GetOwner'), function(msg)
    ao.send({
        Target = msg.From,
        Data = Owner
    });
end)

--[[ao.send({
    Target = Owner,
    Action = "Activate"
});]] --
