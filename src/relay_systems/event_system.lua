local eventId = 1

local function event(msg)
    --creates and event and inserts it into the Events table
    assert(Owner == msg.From)
    local _event = createEvent(msg);
    table.insert(Events,_event)
    --Brodcast
    for k,v in pairs(Subs) do
        ao.send({
            Target = v,
            Action = "Feed",
            Data = json.encode(_event),
        }) 
    end
end

local function createEvent(msg)
    local _event = json.decode(msg.data);
    local currentId = eventId
    eventId = eventId + 1
    _event.id = tostring(currentId)
    _event.pubkey = msg.From
    _event.created_at = msg.Timestamp
    return _event
end

return {
    profile = event,
    token = createEvent,
}