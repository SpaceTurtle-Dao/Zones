local bint = require('utils.bint')(256)
local Event = require('event')
local Filter = require('filter')
local systems = require('systems.systems')

-- Define types
global type Balance = string
global Variant: string
global SubscriptionCost: string = "1000000000000"
global Subscriptions: {string:string}
global Events:{Event}

-- Utils helper functions
local utils = {
  add = function(a: Balance, b: Balance): Balance
    return tostring(bint(a) + bint(b))
  end,
  subtract = function(a: Balance, b: Balance): Balance
    return tostring(bint(a) - bint(b))
  end,
  toBalanceValue = function(a: number): Balance
    return tostring(bint(a))
  end,
  toNumber = function(a: Balance): number
    return tonumber(a)
  end
}

-- Initialize global variables
Variant = "0.0.1"
Subscriptions = Subscriptions or { }
Events = Events or { }

local function cost(msg: Message)
  assert(ao.env.Process.Owner == msg.From)
  utils.toNumber(msg.Tags.Cost)
  SubscriptionCost = msg.Tags.Cost
end

local function event(msg: Message)
  assert(ao.env.Process.Owner == msg.From)
  local _event:Event = systems.event(msg.Data);
  table.insert(Events,_event)
end

local function req(msg: Message)
  if not Subscriptions[msg.Tags.Sender] then Subscriptions[msg.Tags.Sender] = "0" end
  local quantity = Subscriptions[msg.Tags.Sender];
  Subscriptions[msg.Tags.Sender] = utils.add(quantity, msg.Tags.Quantity)
  
  --local filters:{Filter} = systems.filters(msg.Tags.Filters);
  --local subscription_id = msg.Tags["subscription_id"]
end

local function close(msg: Message)
  if not Subscriptions[msg.Tags.Sender] then Subscriptions[msg.Tags.Sender] = "0" end
  local quantity = Subscriptions[msg.Tags.Sender];
  if utils.toNumber(quantity) <= 0 then return end
  --return funds and set balance to 0
  Subscriptions[msg.Tags.From] = "0"
end

local function creditNotice(msg: Message)
  if utils.toNumber(msg.Tags.Quantity) < utils.toNumber(SubscriptionCost) then
    --[[return funds and send message about insufficient funds]]-- 
  end
  local subscription_id = msg.Tags["X-Subscription_Id"]
end                

local function debitNotice(msg: Message)
end

-- Add handlers
Handlers.add('EVENT', Handlers.utils.hasMatchingTag('Action', 'EVENT'), event)
Handlers.add('REQ', Handlers.utils.hasMatchingTag('Action', 'REQ'), req)
Handlers.add('CLOSE', Handlers.utils.hasMatchingTag('Action', 'CLOSE'), close)
Handlers.add('Cost', Handlers.utils.hasMatchingTag('Action', 'Cost'), cost)
Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), creditNotice)
Handlers.add('Debit-Notice', Handlers.utils.hasMatchingTag('Action', 'Debit-Notice'), debitNotice)