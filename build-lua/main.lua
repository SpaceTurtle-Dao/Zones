local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local table = _tl_compat and _tl_compat.table or table; local bint = require('utils.bint')(256)
local Event = require('event')

local rxJson = require('json')
local systems = require('systems.systems')


Balance = {}




SubscriptionCost = "1000000000000"
FeedCost = "1000000000000"






local utils = {
   add = function(a, b)
      return tostring(bint(a) + bint(b))
   end,
   subtract = function(a, b)
      return tostring(bint(a) - bint(b))
   end,
   toBalanceValue = function(a)
      return tostring(bint(a))
   end,
   toNumber = function(a)
      return tonumber(a)
   end,
}


Variant = "0.0.1"
Subscriptions = Subscriptions or {}
Events = Events or {}
Feed = Feed or {}
Token = ""

local function fetchFeed(msg)
   local page = utils.toNumber(msg.Tags.Page)
   local size = utils.toNumber(msg.Tags.Size)
   local results = systems.fetch(Events, page, size)
   ao.send({
      Target = msg.From,
      Data = rxJson.encode(results),
   })
end

local function info(msg)
   ao.send({
      Target = msg.From,
      Token = Token,
      Profile = rxJson.encode(Profile),
      SubscriptionCost = SubscriptionCost,
   })
end

local function profile(msg)

   assert(ao.env.Process.Owner == msg.From)
   local _event = systems.event(msg);
   if _event.kind == 0 then
      Profile = _event
   end
end

local function token(msg)

   assert(ao.env.Process.Owner == msg.From)
   Token = msg.Tags.Token
end

local function withdraw(msg)

   assert(ao.env.Process.Owner == msg.From)
   ao.send({
      Target = msg.Tags.Token,
      Quantity = msg.Tags.Quantity,
      Recipient = msg.Tags.Recipient,
   })
end

local function cost(msg)

   assert(ao.env.Process.Owner == msg.From)
   utils.toNumber(msg.Tags.Cost)
   SubscriptionCost = msg.Tags.Cost
end

local function feed(msg)
   if not Subs[msg.From] then return end
   local _event = systems.event(msg);
   table.insert(Feed, _event)
end

local function payedFeed(msg)


   if utils.toNumber(msg.Tags.Quantity) < utils.toNumber(FeedCost) then

      ao.send({
         Target = msg.From,
         Quantity = msg.Tags.Quantity,
         Recipient = msg.Tags.Sender,
      })
      return
   end
   if not Subs[msg.From] then return end
   local _event = systems.event(msg);
   table.insert(Feed, _event)
end

local function event(msg)

   assert(ao.env.Process.Owner == msg.From)
   local _event = systems.event(msg);
   table.insert(Events, _event)

end

local function subscribe(msg)

   if utils.toNumber(msg.Tags.Quantity) < utils.toNumber(SubscriptionCost) then

      ao.send({
         Target = msg.From,
         Quantity = msg.Tags.Quantity,
         Recipient = msg.Tags.Sender,
      })
      return
   end
   if not Subscriptions[msg.Tags.Sender] then Subscriptions[msg.Tags.Sender] = "0" end
   local quantity = Subscriptions[msg.Tags.Sender];
   Subscriptions[msg.Tags.Sender] = utils.add(quantity, msg.Tags.Quantity)



end

local function close(msg)

   if not Subscriptions[msg.Tags.Sender] then Subscriptions[msg.Tags.Sender] = "0" end
   local quantity = Subscriptions[msg.Tags.Sender];
   if utils.toNumber(quantity) <= 0 then return end

   Subscriptions[msg.From] = "0"
end

local function creditNotice(msg)
   if msg.From ~= Token then

      ao.send({
         Target = msg.From,
         Quantity = msg.Tags.Quantity,
         Recipient = msg.Tags.Sender,
      })
      return
   end
   if not msg.Tags["X-Type"] then
      ao.send({
         Target = msg.From,
         Quantity = msg.Tags.Quantity,
         Recipient = msg.Tags.Sender,
      })
      return
   end

   local _type = msg.Tags["X-Type"]

   if _type == "Feed" then
      payedFeed(msg)
      return
   end
   if _type == "Subscribe" then
      subscribe(msg)
      return
   end
   ao.send({
      Target = msg.From,
      Quantity = msg.Tags.Quantity,
      Recipient = msg.Tags.Sender,
   })
end




Handlers.add('EVENT', Handlers.utils.hasMatchingTag('Action', 'EVENT'), event)
Handlers.add('CLOSE', Handlers.utils.hasMatchingTag('Action', 'CLOSE'), close)
Handlers.add('Cost', Handlers.utils.hasMatchingTag('Action', 'Cost'), cost)
Handlers.add('Token', Handlers.utils.hasMatchingTag('Action', 'Token'), token)
Handlers.add('Profile', Handlers.utils.hasMatchingTag('Action', 'Profile'), profile)
Handlers.add('Feed', Handlers.utils.hasMatchingTag('Action', 'Feed'), feed)
Handlers.add('FetchFeed', Handlers.utils.hasMatchingTag('Action', 'FetchFeed'), fetchFeed)
Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), info)
Handlers.add('Withdraw', Handlers.utils.hasMatchingTag('Action', 'Withdraw'), withdraw)
Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), creditNotice)
