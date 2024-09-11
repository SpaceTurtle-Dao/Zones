local bint = require('utils.bint')(256)
local Event = require('event')
local Filter = require('filter')
local rxJson = require('json')
local systems = require('systems.systems')

-- Define types
global type Balance = string
global Variant: string
global Token: string
global Profile:Event
global Descrition: string
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
Token = "" -- AO or wAR token


local function info(msg: Message)
  ao.send({
    Target = msg.From,
    Token = Token,
    Profile = rxJson.encode(Profile),
    SubscriptionCost = SubscriptionCost
  })
end

local function profile(msg: Message)
  --sets the profile event
  assert(ao.env.Process.Owner == msg.From)
  local _event = systems.event(msg.Data);
  if _event.kind == 0 then 
    Profile = _event
  end

local function token(msg: Message)
  --sets the cost of a subscription
  assert(ao.env.Process.Owner == msg.From)
  Token = msg.Tags.Token
end

local function cost(msg: Message)
  --sets the cost of a subscription
  assert(ao.env.Process.Owner == msg.From)
  utils.toNumber(msg.Tags.Cost)
  SubscriptionCost = msg.Tags.Cost
end

local function event(msg: Message)
  --creates and event and inserts it into the Events table
  assert(ao.env.Process.Owner == msg.From)
  local _event:Event = systems.event(msg.Data);
  table.insert(Events,_event)
  --Brodcast
end

local function req(msg: Message)
  --subscribes to events from this relay
  if not Subscriptions[msg.Tags.Sender] then Subscriptions[msg.Tags.Sender] = "0" end
  local quantity = Subscriptions[msg.Tags.Sender];
  Subscriptions[msg.Tags.Sender] = utils.add(quantity, msg.Tags.Quantity)
  
  --local filters:{Filter} = systems.filters(msg.Tags.Filters);
  --local subscription_id = msg.Tags["subscription_id"]
end

local function close(msg: Message)
  --removes relay from subscriptions and returns any remaining balance
  if not Subscriptions[msg.Tags.Sender] then Subscriptions[msg.Tags.Sender] = "0" end
  local quantity = Subscriptions[msg.Tags.Sender];
  if utils.toNumber(quantity) <= 0 then return end
  --return funds and set balance to 0
  Subscriptions[msg.From] = "0"
end

local function creditNotice(msg: Message)
  if msg.From ~= Token then
    --[[return funds and send message about unsupported token]]--
    ao.send({
      Target = msg.From,
      Quantity = msg.Tags.Quantity,
      Recipient = msg.Tags.Sender
    })
    return
  end
  if utils.toNumber(msg.Tags.Quantity) < utils.toNumber(SubscriptionCost) then
    --[[return funds and send message about insufficient funds]]-- 
    ao.send({
      Target = msg.From,
      Quantity = msg.Tags.Quantity,
      Recipient = msg.Tags.Sender
    })
    return 
  end
  req(msg)
end                

local function debitNotice(msg: Message)
end

-- Add handlers
Handlers.add('EVENT', Handlers.utils.hasMatchingTag('Action', 'EVENT'), event)
Handlers.add('CLOSE', Handlers.utils.hasMatchingTag('Action', 'CLOSE'), close)
Handlers.add('Cost', Handlers.utils.hasMatchingTag('Action', 'Cost'), cost)
Handlers.add('Token', Handlers.utils.hasMatchingTag('Action', 'Token'), token)
Handlers.add('Profile', Handlers.utils.hasMatchingTag('Action', 'Profile'), profile)
Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), info)
Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), creditNotice)
Handlers.add('Debit-Notice', Handlers.utils.hasMatchingTag('Action', 'Debit-Notice'), debitNotice)