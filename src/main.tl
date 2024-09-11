--local bint = require('utils.bint')(256)
--local Filter = require('filter')
local query_system = require('relay_systems.query_system')
local event_system = require('relay_systems.event_system')
local feed_system = require('relay_systems.feed_system')
local profile_system = require('relay_systems.profile_system')
local subscription_system = require('relay_systems.subscription_system')
local token_system = require('relay_systems.token_system')
require('database')

-- Add handlers
Handlers.add('Event', Handlers.utils.hasMatchingTag('Action', 'Event'), event_system.event)
Handlers.add('Close', Handlers.utils.hasMatchingTag('Action', 'Close'), subscription_system.close)

Handlers.add('Subscribe', Handlers.utils.hasMatchingTag('Action', 'Subscribe'), subscription_system.subscribe)
Handlers.add('UnSubscribe', Handlers.utils.hasMatchingTag('Action', 'UnSubscribe'), subscription_system.subscribe)

Handlers.add('Feed', Handlers.utils.hasMatchingTag('Action', 'Feed'), feed_system.feed)

Handlers.add('SubscriptionCost', Handlers.utils.hasMatchingTag('Action', 'SubscriptionCost'), subscription_system.subscriptionCost)
Handlers.add('FeedCost', Handlers.utils.hasMatchingTag('Action', 'FeedCost'), feed_system.feedCost)


Handlers.add('Token', Handlers.utils.hasMatchingTag('Action', 'Token'), profile_system.token)
Handlers.add('Profile', Handlers.utils.hasMatchingTag('Action', 'Profile'), profile_system.profile)

Handlers.add('Withdraw', Handlers.utils.hasMatchingTag('Action', 'Withdraw'), profile_system.withdraw)
Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), token_system.creditNotice)
--Handlers.add('Debit-Notice', Handlers.utils.hasMatchingTag('Action', 'Debit-Notice'), debitNotice)

Handlers.add('FetchFeed', Handlers.utils.hasMatchingTag('Action', 'FetchFeed'), query_system.fetchFeed)
Handlers.add('FetchEvents', Handlers.utils.hasMatchingTag('Action', 'FetchEvents'), query_system.fetchEvents)
Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), query_system.info)
