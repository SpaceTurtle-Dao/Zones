local bint = require('token.utils.bint')(256)
local rxJson = require('json')
local dummy_package = require('dummy.dummy')
dummy_package.print_dummy(1)

-- Define types
global type Balance = string
global type Address = string
global Variant: string
global Balances: {string:string}
global Memes: {string:string}
global Replies: {string:string}

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
Memes = Memes or { }

local function meme(msg:Message)

end

local function reply(msg:Message)

end

local function profile(msg:Message)

end

local function fetchMemes(msg:Message)
end

local function kind01(msg: Message)
  if msg.Tags.Qaunity == "Some cost" then end
  --logic
end

local function kind02(msg: Message)
  if msg.Tags.Qaunity == "Some cost" then end
  --logic
end

local function creditNotice(msg: Message)
  --replies
  if msg.Tags["X-Kind"] == "01" then kind01(msg) return end
  if msg.Tags["X-Kind"] == "02" then kind02(msg) return end
end                

local function debitNotice(msg: Message)
  ao.send({
    Target = msg.From,
    Data = Colors.gray .. "Successfully burned " .. Colors.blue .. msg.Tags.Quantity .. Colors.reset
  })
end

-- Add handlers
Handlers.add('Meme', Handlers.utils.hasMatchingTag('Action', 'Meme'), meme)
Handlers.add('Profile', Handlers.utils.hasMatchingTag('Action', 'Profile'), profile)
Handlers.add('FetchMemes', Handlers.utils.hasMatchingTag('Action', 'FetchMemes'), fetchMemes)
Handlers.add('Credit-Notice', Handlers.utils.hasMatchingTag('Action', 'Credit-Notice'), creditNotice)
Handlers.add('Debit-Notice', Handlers.utils.hasMatchingTag('Action', 'Debit-Notice'), debitNotice)