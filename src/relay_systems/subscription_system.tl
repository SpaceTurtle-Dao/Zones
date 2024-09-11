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
--subscribes to events from this relay
if utils.toNumber(msg.Tags.Quantity) < utils.toNumber(SubscriptionCost) then
    --[[return funds and send message about insufficient funds]]-- 
    ao.send({
        Target = msg.From,
        Quantity = msg.Tags.Quantity,
        Recipient = msg.Tags.Sender
        })
        return 
    end
    if not Subs[msg.Tags.Sender] then Subs[msg.Tags.Sender] = "0" end
    local quantity = Subs[msg.Tags.Sender];
    Subs[msg.Tags.Sender] = utils.add(quantity, msg.Tags.Quantity)

    --local filters:{Filter} = systems.filters(msg.Tags.Filters);
    --local subscription_id = msg.Tags["subscription_id"]
end

local function close(msg: Message)
    --removes relay from Subs and returns any remaining balance
    if not Subs[msg.Tags.Sender] then Subs[msg.Tags.Sender] = "0" end
    local quantity = Subs[msg.Tags.Sender];
    if utils.toNumber(quantity) <= 0 then return end
    --return funds and set balance to 0
    Subs[msg.From] = "0"
end


return {
    subscriptionCost = subscriptionCost,
    subscribe = subscribe,
    close = close,
}