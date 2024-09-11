local rxJson = require('json')
local utils = require('utils.utils')
local systems = require('systems.systems')
require('database')

local function info(msg: Message)
    ao.send({
        Target = msg.From,
        Token = Token,
        Profile = rxJson.encode(Profile),
        SubscriptionCost = SubscriptionCost,
        FeedCost = FeedCost
    })
end
  
local function fetchFeed(msg: Message)
    local page = utils.toNumber(msg.Tags.Page)
    local size = utils.toNumber(msg.Tags.Size)
    local results = systems.fetch(Feed,page,size,msg.Tags.Kinds)
    ao.send({
        Target = msg.From,
        Data = rxJson.encode(results)
    })
end
  
local function fetchEvents(msg: Message)
    local page = utils.toNumber(msg.Tags.Page)
    local size = utils.toNumber(msg.Tags.Size)
    local results = systems.fetch(Events,page,size,msg.Tags.Kinds)
    ao.send({
        Target = msg.From,
        Data = rxJson.encode(results)
    })
end

return {
    info = info,
    fetchFeed = fetchFeed,
    fetchEvents = fetchEvents
}