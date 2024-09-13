--local Filter = require('filter')
local function feedCost(msg)
    --sets the cost of a subscription
    --assert(ao.env.Process.Owner == msg.From)
    utils.toNumber(msg.Cost)
    SubscriptionCost = msg.Cost
end
  
local function feed(msg)
    if not Subs[msg.From] then return end
    local _event = event(msg.Data);
    table.insert(Feed,_event)
end

return {
    feedCost = feedCost,
    feed = feed,
    payedFeed = payedFeed
}