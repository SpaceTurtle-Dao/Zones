local function subscriptionCost(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode(Subs)
    })
end



local function unSubscribe(msg)
    --unsubscribes from a relay
    --assert(ao.env.Process.Owner == msg.From)
    Handlers.add(msg.Relay, Handlers.utils.hasMatchingTag('Action', msg.Relay), function(_msg)
        assert(_msg.From == msg.Relay)
        Handlers.remove(msg.Relay)
        Subscriptions[_msg.From] = nil
    end)
    ao.send({
        Target = msg.Relay,
        Action = "Close",
    })
end

local function close(msg)
    --removes relay from Subs
    ao.send({
        Target = msg.From,
        Action = ao.id,
    })
    if not Subs[msg.From] then return end
    Subs[msg.From] = nil
end

return {
    subscriptionCost = subscriptionCost,
    subscribe = subscribe,
    unSubscribe = unSubscribe,
    close = close
}