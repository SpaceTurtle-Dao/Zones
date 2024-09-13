--local Filter = require('filter')
local function feedCost(msg)
    --sets the cost of a subscription
    --assert(ao.env.Process.Owner == msg.From)
    utils.toNumber(msg.Cost)
    SubscriptionCost = msg.Cost
end

return {
    feedCost = feedCost,
    feed = feed,
    payedFeed = payedFeed
}