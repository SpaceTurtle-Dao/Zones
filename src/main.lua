-- Initialize global variables
local ao = require('ao')
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


Variant = "0.0.1"
Token = "WPyLgOqELOyN_BoTNdeEMZp5sz3RxDL19IGcs3A9IPc" -- AO or wAR token currently set to swappy tokens for testing
SubscriptionCost = "1000000"
FeedCost = "1000000"
EventId = 1
if not Profile then Profile = {} end
if not SubscriptionRequest then SubscriptionRequest = {} end
if not Subscriptions then Subscriptions = {} end
if not Subs then Subs = {} end
if not Events then Events = {} end
if not Feed then Feed = {} end

local function info(msg)
    ao.send({
        Target = msg.From,
        Token = Token,
        Profile = json.encode(Profile),
        SubscriptionCost = SubscriptionCost,
        FeedCost = FeedCost
    })
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
    local page = Utils.toNumber(msg.Page)
    local size = Utils.toNumber(msg.Size)
    local results = fetch(Feed, page, size)
    ao.send({
        Target = msg.From,
        Data = json.encode(results)
    })
end

local function fetchEvents(msg)
    local page = Utils.toNumber(msg.Page)
    local size = Utils.toNumber(msg.Size)
    local results = fetch(Events, page, size)
    ao.send({
        Target = msg.From,
        Data = json.encode(results)
    })
end

local function fetchSubs(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode(Subs)
    })
end

local function fetchSubscriptions(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode(Subscriptions)
    })
end

local function createEvent(msg)
    local _event = json.decode(msg.Data);
    local currentId = EventId
    EventId = EventId + 1
    _event.id = tostring(currentId)
    _event.pubkey = ao.id
    _event.created_at = msg.Timestamp
    return _event
end

local function event(msg)
    --creates and event and inserts it into the Events table
    --assert(Owner == msg.From)
    local _event = createEvent(msg);
    table.insert(Events, _event)
    ao.send({
        Target = msg.From,
        Data = json.encode(_event),
    })
    --Brodcast
    for k, v in ipairs(Subs) do
        ao.send({
            Target = v,
            Action = "Feed",
            Data = json.encode(_event),
        })
    end
end

local function feed(msg)
    local isSubscription = utils.includes(msg.From,Subscriptions)
    if isSubscription == false then return end
    local _event = json.decode(msg.Data);
    table.insert(Feed,_event)
end

local function subscribe(msg)
    SubscriptionRequest[msg.Relay] = true
    ao.send({
        Target = msg.Token,
        Action = "Transfer",
        Quantity = msg.Quantity,
        Recipient = msg.Relay,
        ["X-Type"] = "SubscriptionRequest"
    })
end

local function unsubscribe(msg)
    SubscriptionRequest[msg.Relay] = false
    ao.send({
        Target = msg.Relay,
        Action = "UnSubscribed"
    })
end

local function subscriptionRequest(msg)
    if Utils.toNumber(msg.Quantity) < Utils.toNumber(SubscriptionCost) then
        --[[return funds and send message about insufficient funds]] --
        ao.send({
            Target = msg.From,
            Quantity = msg.Quantity,
            Recipient = msg.Sender
        })
        return
    end
    utils.filter(function(val) return val ~= msg.Sender end, Subs)
    table.insert(Subs, msg.Sender)
    ao.send({
        Target = msg.Sender,
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

Handlers.add('Event', Handlers.utils.hasMatchingTag('Action', 'Event'), function(msg)
    event(msg)
end)

Handlers.add('Feed', Handlers.utils.hasMatchingTag('Action', 'Feed'), function(msg)
    feed(msg)
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
