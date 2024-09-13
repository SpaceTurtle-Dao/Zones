
--[[Handlers.add('Event', Handlers.utils.hasMatchingTag('Action', 'Event'), function(msg)
    event(msg)
end)


Handlers.add('Feed', Handlers.utils.hasMatchingTag('Action', 'Feed'), function(msg)
    feed(msg)
end)

Handlers.add('SubscriptionCost', Handlers.utils.hasMatchingTag('Action', 'SubscriptionCost'), function(msg)
    subscriptionCost(msg)
end)
Handlers.add('FeedCost', Handlers.utils.hasMatchingTag('Action', 'FeedCost'), function(msg)
    feedCost(msg)
end)


Handlers.add('Token', Handlers.utils.hasMatchingTag('Action', 'Token'), function(msg)
    token(msg)
end)
Handlers.add('Profile', Handlers.utils.hasMatchingTag('Action', 'Profile'), function(msg)
    profile(msg)
end)

Handlers.add('Withdraw', Handlers.utils.hasMatchingTag('Action', 'Withdraw'), function(msg)
    withdraw(msg)
end)
Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), function(msg)
    creditNotice(msg)
end)
Handlers.add('Debit-Notice', Handlers.utils.hasMatchingTag('Action', 'Debit-Notice'), debitNotice)

Handlers.add('FetchFeed', Handlers.utils.hasMatchingTag('Action', 'FetchFeed'), function(msg)
    fetchFeed(msg)
end)]]--#region