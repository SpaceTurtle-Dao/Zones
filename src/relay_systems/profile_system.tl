local systems = require('systems.systems')
require('database')

local function profile(msg: Message)
    --sets the profile event
    assert(ao.env.Process.Owner == msg.From)
    local _event = systems.createEvent(msg);
    if _event.kind == 0 then 
        Profile = _event
    end
end
  
local function token(msg: Message)
    --sets the cost of a subscription
    assert(ao.env.Process.Owner == msg.From)
    Token = msg.Tags.Token
end

local function withdraw(msg: Message)
    --Withdraws Tokens
    assert(ao.env.Process.Owner == msg.From)
    ao.send({
        Target = msg.Tags.Token,
        Quantity = msg.Tags.Quantity,
        Recipient = msg.Tags.Recipient
    })
end

return {
    profile = profile,
    token = token,
    withdraw = withdraw
}