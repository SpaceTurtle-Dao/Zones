local Event = require('event')

global Variant: string
global Token: string
global Profile:Event
global SubscriptionCost: string = "1000000000000"
global FeedCost: string = "1000000000000"
global Subscriptions: {string:string}
global Subs: {string:string}
global Events:{Event}
global Feed:{Event}

-- Initialize global variables
Variant = Variant or "0.0.1"
Subscriptions = Subscriptions or { }
Events = Events or { }
Feed = Feed or { }
Token = Token or "" -- AO or wAR token