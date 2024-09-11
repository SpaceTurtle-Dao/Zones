--local Filter = require('filter')
local systems = require('systems.systems')
require('database')
local utils = require('utils.utils')

local function feedCost(msg: Message)
    --sets the cost of a subscription
    assert(ao.env.Process.Owner == msg.From)
    utils.toNumber(msg.Tags.Cost)
    SubscriptionCost = msg.Tags.Cost
end
  
local function feed(msg: Message)
    if not Subs[msg.From] then return end
    local _event = systems.event(msg.Data);
    table.insert(Feed,_event)
end

local function payedFeed(msg: Message)
    --pays relay to add event to feed since relay is not subscribed 
    --basically paying for attention
    if utils.toNumber(msg.Tags.Quantity) < utils.toNumber(FeedCost) then
        --[[return funds and send message about insufficient funds]]-- 
        ao.send({
        Target = msg.From,
        Quantity = msg.Tags.Quantity,
        Recipient = msg.Tags.Sender
        })
        return 
    end
    if not Subs[msg.From] then return end
    local _event = systems.event(msg.Tags.Event);
    table.insert(Feed,_event)
end

return {
    feedCost = feedCost,
    feed = feed,
    payedFeed = payedFeed,
}