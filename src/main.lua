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

Handlers.add('Subs', Handlers.utils.hasMatchingTag('Action', 'Subs'), function(msg)
    fetchSubs(msg)
end)

Handlers.add('Subscriptions', Handlers.utils.hasMatchingTag('Action', 'Subscriptions'), function(msg)
    fetchSubscriptions(msg)
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
