local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local table = _tl_compat and _tl_compat.table or table; local Event = require('event')

local systems = require('systems.systems')
require('database')
local utils = require('utils.utils')


local function profile(msg)

   assert(ao.env.Process.Owner == msg.From)
   local _event = systems.createEvent(msg);
   if _event.kind == 0 then
      Profile = _event
   end
end

local function token(msg)

   assert(ao.env.Process.Owner == msg.From)
   Token = msg.Tags.Token
end

local function subscriptionCost(msg)

   assert(ao.env.Process.Owner == msg.From)
   utils.toNumber(msg.Tags.Cost)
   SubscriptionCost = msg.Tags.Cost
end

local function feedCost(msg)

   assert(ao.env.Process.Owner == msg.From)
   utils.toNumber(msg.Tags.Cost)
   SubscriptionCost = msg.Tags.Cost
end

local function feed(msg)
   if not Subs[msg.From] then return end
   local _event = systems.event(msg.Data);
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
   local _event = systems.event(msg.Tags.Event);
   table.insert(Feed, _event)
end

local function event(msg)

   assert(ao.env.Process.Owner == msg.From)
   local _event = systems.createEvent(msg);
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

local function withdraw(msg)

   assert(ao.env.Process.Owner == msg.From)
   ao.send({
      Target = msg.Tags.Token,
      Quantity = msg.Tags.Quantity,
      Recipient = msg.Tags.Recipient,
   })
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

return {
   profile = profile,
   token = token,
   subscriptionCost = subscriptionCost,
   feedCost = feedCost,
   feed = feed,
   payedFeed = payedFeed,
   event = event,
   subscribe = subscribe,
   close = close,
   withdraw = withdraw,
   creditNotice = creditNotice,
}
