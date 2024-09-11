local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local table = _tl_compat and _tl_compat.table or table; local bint = require('utils.bint')(256)
local Event = require('event')
local Filter = require('filter')
local systems = require('systems.systems')


Balance = {}





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
Balances = Balances or {}
Events = Events or {}

local function event(msg)
   assert(ao.env.Process.Owner == msg.From)
   local _event = systems.event(msg);
   table.insert(Events, _event)
end

local function req(msg)
   local filters = systems.filters(msg);
   local subscription_id = msg.Tags["subscription_id"]
end

local function close(msg)
   local subscription_id = msg.Tags["subscription_id"]
end

local function creditNotice(msg)
end

local function debitNotice(msg)
end


Handlers.add('EVENT', Handlers.utils.hasMatchingTag('Action', 'EVENT'), event)
Handlers.add('REQ', Handlers.utils.hasMatchingTag('Action', 'REQ'), req)
Handlers.add('CLOSE', Handlers.utils.hasMatchingTag('Action', 'CLOSE'), close)
Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), creditNotice)
Handlers.add('Debit-Notice', Handlers.utils.hasMatchingTag('Action', 'Debit-Notice'), debitNotice)
