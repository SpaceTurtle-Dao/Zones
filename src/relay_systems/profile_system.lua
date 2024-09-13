local function profile(msg)
    --sets the profile event
    assert(Owner == msg.From)
    local _event = createEvent(msg);
    if _event.kind == 0 then
        Profile = _event
    end
end

local function token(msg)
    --sets the cost of a subscription
    assert(Owner == msg.From)
    Token = msg.Token
end

local function withdraw(msg)
    --Withdraws Tokens
    assert(Owner == msg.From)
    ao.send({
        Target = msg.Token,
        Quantity = msg.Quantity,
        Recipient = msg.Recipient
    })
end


return {
    profile = profile,
    token = token,
    withdraw = withdraw
}