
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------

do
    local searchers = package.searchers or package.loaders
    local origin_seacher = searchers[2]
    searchers[2] = function(path)
        local files =
        {
------------------------
-- Modules part begin --
------------------------

["database"] = function()
--------------------
-- Module: 'database'
--------------------
-- Initialize global variables
local ao = require('ao')
local json = require('json');
local bint = require('.bint')(256)

Variant = "0.0.1"
Token = "WPyLgOqELOyN_BoTNdeEMZp5sz3RxDL19IGcs3A9IPc" -- AO or wAR token currently set to swappy tokens for testing
SubscriptionCost = "1000000"
FeedCost = "1000000"
if not Profile then Profile = { } end
if not Subscriptions then Subscriptions = {} end
if not Subs then Subs = {} end
if not Events then Events = {} end
if not Feed then Feed = {} end
end,

["utils"] = function()
--------------------
-- Module: 'utils'
--------------------
-- Utils helper functions
utils = {
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

end,

["relay_systems.query_system"] = function()
--------------------
-- Module: 'relay_systems.query_system'
--------------------
local function fetch(tbl, page, size, kinds)
    local tempArray = {}
    for k, v in pairs(tbl) do
        for _k,_v in pairs(json.decode(kinds)) do
            if v.kind == _v then
                table.insert(tempArray, v)
                break
            end
        end
        
    end
    local start = (page - 1) * size + 1
    local endPage = page * size
    local result = {};
    for i = start, endPage do
        if tempArray[i] then
            table.insert(result, tempArray[i])
        else
            break
        end
    end
    return result;
end

local function info(msg)
    ao.send({
        Target = msg.From,
        Token = Token,
        Profile = json.encode(Profile),
        SubscriptionCost = SubscriptionCost,
        FeedCost = FeedCost
    })
end

local function fetchFeed(msg)
    local page = utils.toNumber(msg.Page)
    local size = utils.toNumber(msg.Size)
    local results = fetch(Feed, page, size, msg.Kinds)
    ao.send({
        Target = msg.From,
        Data = json.encode(results)
    })
end

local function fetchEvents(msg)
    local page = utils.toNumber(msg.Page)
    local size = utils.toNumber(msg.Size)
    local results = fetch(Events, page, size, msg.Kinds)
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

return {
    info = info,
    fetchFeed = fetchFeed,
    fetchEvents = fetchEvents,
    fetchSubs = fetchSubs,
    fetchSubscriptions = fetchSubscriptions,
}
end,

["relay_systems.subscription_system"] = function()
--------------------
-- Module: 'relay_systems.subscription_system'
--------------------
local function subscriptionCost(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode(Subs)
    })
end

local function subscribe(msg)
    --subscribes to events from another relay
    --assert(ao.env.Process.Owner == msg.From)
    --[[Handlers.add(msg.Relay, Handlers.utils.hasMatchingTag('Action', msg.Relay),
        function(_msg)
            assert(_msg.From == msg.Relay)
            if not msg.Status or msg.Status ~= "200" then return end
            table.insert(Subscriptions,_msg.From)
            Handlers.remove(msg.Relay)
    end)]]--
    ao.send({
        Target = msg.Token,
        Action = "Transfer",
        Quantity = msg.Quantity,
        Recipient = msg.Relay,
        ["X-Type"] = "Req"
    })
end

local function unSubscribe(msg)
    --unsubscribes from a relay
    --assert(ao.env.Process.Owner == msg.From)
    Handlers.add(msg.Relay, Handlers.utils.hasMatchingTag('Action', msg.Relay), function(_msg)
        assert(_msg.From == msg.Relay)
        Handlers.remove(msg.Relay)
        Subscriptions[_msg.From] = nil
    end)
    ao.send({
        Target = msg.Relay,
        Action = "Close",
    })
end

local function close(msg)
    --removes relay from Subs
    ao.send({
        Target = msg.From,
        Action = ao.id,
    })
    if not Subs[msg.From] then return end
    Subs[msg.From] = nil
end

return {
    subscriptionCost = subscriptionCost,
    subscribe = subscribe,
    unSubscribe = unSubscribe,
    close = close
}
end,

["relay_systems.token_system"] = function()
--------------------
-- Module: 'relay_systems.token_system'
--------------------
local function req(msg)
    --subscribes to events from this relay
    if utils.toNumber(msg.Quantity) < utils.toNumber(SubscriptionCost) then
        --[[return funds and send message about insufficient funds]] --
        ao.send({
            Target = msg.From,
            Quantity = msg.Quantity,
            Recipient = msg.Sender
        })
        ao.send({
            Target = msg.Sender,
            Action = ao.id,
            Status = "400"
        })
        return
    end
    table.insert(Subs,msg.Sender)
    ao.send({
        Target = msg.Sender,
        Action = ao.id,
        Status = "200"
    })
    --local filters:{Filter} = systems.filters(msg.Tags.Filters);
    --local subscription_id = msg.Tags["subscription_id"]
end

local function payedFeed(msg)
    --pays relay to add event to feed since relay is not subscribed 
    --basically paying for attention
    if utils.toNumber(msg.Quantity) < utils.toNumber(FeedCost) then
        --[[return funds and send message about insufficient funds]]-- 
        ao.send({
        Target = msg.From,
        Quantity = msg.Quantity,
        Recipient = msg.Sender
        })
        return 
    end
    if not Subs[msg.From] then return end
    local _event = systems.event(msg.Event);
    table.insert(Feed,_event)
end

local function creditNotice(msg)
    local _type = msg["X-Type"]
    if msg.From ~= Token then
        --[[return funds and send message about unsupported token]] --
        ao.send({
            Target = msg.From,
            Quantity = msg .. Quantity,
            Recipient = msg .. Sender
        })
        return
    end
    if not _type then
        ao.send({
            Target = msg.From,
            Quantity = msg.Quantity,
            Recipient = msg.Sender
        })
        return
    end

    if _type == "Feed" then
        payedFeed(msg)
        return
    end
    if _type == "Req" then
        req(msg)
        return
    end
    ao.send({
        Target = msg.From,
        Quantity = msg.Quantity,
        Recipient = msg.Sender
    })
end

return {
    creditNotice = creditNotice
}

--local function debitNotice(msg: Message)end

end,

----------------------
-- Modules part end --
----------------------
        }
        if files[path] then
            return files[path]
        else
            return origin_seacher(path)
        end
    end
end
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------
local query_system = require("relay_systems.query_system")
local subscription_system = require("relay_systems.subscription_system")
local token_system = require("relay_systems.token_system")

Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(msg)
    query_system.info(msg)
end)

Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), function(msg)
    query_system.fetchEvents(msg)
end)

Handlers.add('Close', Handlers.utils.hasMatchingTag('Action', 'Close'), function(msg)
    subscription_system.close(msg)
end)

Handlers.add('Subscribe', Handlers.utils.hasMatchingTag('Action', 'Subscribe'), function(msg)
    subscription_system.subscribe(msg)
end)
Handlers.add('UnSubscribe', Handlers.utils.hasMatchingTag('Action', 'UnSubscribe'), function(msg)
    subscription_system.unSubscribe(msg)
end)

Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), function(msg)
    token_system.creditNotice(msg)
end)