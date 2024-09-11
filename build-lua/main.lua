

local rxJson = require('json')
local systems = require('systems.systems')
local event_system = require('event_system')
require('database')

Balance = {}

local utils = require('utils.utils')


local function info(msg)
   ao.send({
      Target = msg.From,
      Token = Token,
      Profile = rxJson.encode(Profile),
      SubscriptionCost = SubscriptionCost,
      FeedCost = FeedCost,
   })
end

local function fetchFeed(msg)
   local page = utils.toNumber(msg.Tags.Page)
   local size = utils.toNumber(msg.Tags.Size)
   local results = systems.fetch(Feed, page, size, msg.Tags.Kinds)
   ao.send({
      Target = msg.From,
      Data = rxJson.encode(results),
   })
end

local function fetchEvents(msg)
   local page = utils.toNumber(msg.Tags.Page)
   local size = utils.toNumber(msg.Tags.Size)
   local results = systems.fetch(Events, page, size, msg.Tags.Kinds)
   ao.send({
      Target = msg.From,
      Data = rxJson.encode(results),
   })
end






Handlers.add('EVENT', Handlers.utils.hasMatchingTag('Action', 'EVENT'), event_system.event)
Handlers.add('CLOSE', Handlers.utils.hasMatchingTag('Action', 'CLOSE'), event_system.close)
Handlers.add('SubscriptionCost', Handlers.utils.hasMatchingTag('Action', 'SubscriptionCost'), event_system.subscriptionCost)
Handlers.add('FeedCost', Handlers.utils.hasMatchingTag('Action', 'FeedCost'), event_system.feedCost)
Handlers.add('Token', Handlers.utils.hasMatchingTag('Action', 'Token'), event_system.token)
Handlers.add('Profile', Handlers.utils.hasMatchingTag('Action', 'Profile'), event_system.profile)
Handlers.add('Feed', Handlers.utils.hasMatchingTag('Action', 'Feed'), event_system.feed)
Handlers.add('Withdraw', Handlers.utils.hasMatchingTag('Action', 'Withdraw'), event_system.withdraw)
Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), event_system.creditNotice)

Handlers.add('FetchFeed', Handlers.utils.hasMatchingTag('Action', 'FetchFeed'), fetchFeed)
Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), fetchEvents)
Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), info)
