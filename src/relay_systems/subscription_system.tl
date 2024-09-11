--local Filter = require('filter')
require('database')
local utils = require('utils.utils')

local function subscriptionCost(msg: Message)
    --sets the cost of a subscription
    assert(ao.env.Process.Owner == msg.From)
    utils.toNumber(msg.Tags.Cost)
    SubscriptionCost = msg.Tags.Cost
end

local function subscribe(msg: Message)
    --subscribes to events from another relay
    assert(ao.env.Process.Owner == msg.From)
    Handlers.add("subscribe"..msg.Tags.Relay, Handlers.utils.hasMatchingTag('Action', "subscribe"..msg.Tags.Relay), function(_msg:Message)
        assert(_msg.From == msg.Tags.Relay)
        Handlers.remove("subscribe"..msg.Tags.Relay)
        if not msg.Tags.Status or msg.Tags.Status ~= "200" then return end
        Subscriptions[_msg.From] = _msg.From
    end)
    ao.send({
        Target = msg.Tags.Token,
        Action = "Transfer",
        Quantity = msg.Tags.Quantity,
        Recipient = msg.Tags.Relay,
        ["X-Type"] = "Req"
    })
end

local function unSubscribe(msg: Message)
    --unsubscribes from a relay
    assert(ao.env.Process.Owner == msg.From)
    Handlers.add("close"..msg.Tags.Relay, Handlers.utils.hasMatchingTag('Action', "close"..msg.Tags.Relay), function(_msg:Message)
        assert(_msg.From == msg.Tags.Relay)
        Handlers.remove("close"..msg.Tags.Relay)
        Subscriptions[_msg.From] = nil
    end)
    ao.send({
        Target = msg.Tags.Relay,
        Action = "Close",
    })
end

local function req(msg: Message)
    --subscribes to events from this relay
    if utils.toNumber(msg.Tags.Quantity) < utils.toNumber(SubscriptionCost) then
        --[[return funds and send message about insufficient funds]]-- 
        ao.send({
            Target = msg.From,
            Quantity = msg.Tags.Quantity,
            Recipient = msg.Tags.Sender
        })
        ao.send({
            Target = msg.Tags.Sender,
            Action = "subscribe"..ao.id,
            Status = "400" 
        })
        return 
    end
    Subs[msg.Tags.Sender] = msg.Tags.Sender
    ao.send({
        Target = msg.Tags.Sender,
        Action = "subscribe"..ao.id,
        Status = "200" 
    })
    --local filters:{Filter} = systems.filters(msg.Tags.Filters);
    --local subscription_id = msg.Tags["subscription_id"]
end

local function close(msg: Message)
    --removes relay from Subs
    ao.send({
        Target = msg.From,
        Action = "close"..ao.id,
    })
    if not Subs[msg.From] then return end
    Subs[msg.From] = nil
end


return {
    subscriptionCost = subscriptionCost,
    req = req,
    close = close,
    subscribe = subscribe,
    unSubscribe = unSubscribe,
}