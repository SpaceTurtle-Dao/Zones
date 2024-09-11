local bint = require('utils.bint')(256)
local Event = require('event')
local Filter = require('filter')
local systems = require('systems.systems')

-- Define types
global type Balance = string
global Variant: string
global Balances: {string:string}
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
Balances = Balances or { }
Events = Events or { }

local function event(msg: Message)
  assert(ao.env.Process.Owner == msg.From)
  local _event:Event = systems.event(msg);
  table.insert(Events,_event)
end

local function req(msg: Message)
  local filters:{Filter} = systems.filters(msg);
  local subscription_id = msg.Tags["subscription_id"]
end

local function close(msg: Message)
  local subscription_id = msg.Tags["subscription_id"]
end

local function creditNotice(msg: Message)
end                

local function debitNotice(msg: Message)
end

-- Add handlers
Handlers.add('EVENT', Handlers.utils.hasMatchingTag('Action', 'EVENT'), event)
Handlers.add('REQ', Handlers.utils.hasMatchingTag('Action', 'REQ'), req)
Handlers.add('CLOSE', Handlers.utils.hasMatchingTag('Action', 'CLOSE'), close)
Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), creditNotice)
Handlers.add('Debit-Notice', Handlers.utils.hasMatchingTag('Action', 'Debit-Notice'), debitNotice)