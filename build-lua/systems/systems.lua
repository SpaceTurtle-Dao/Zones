local ao = require('ao')
local json = require('json');

local eventId = 1

function createEvent(msg)
    local _event = json.decode(msg.data);
    local currentId = eventId
    eventId = eventId + 1
    _event.id = tostring(currentId)
    _event.pubkey = msg.From
    _event.created_at = msg.Timestamp
    return _event
end

function event(value)
    local _event = json.decode(value);
    return _event
end

function filters(value)
    local filters = json.decode(value)
    return filters
end

function fetch(tbl, page, size, kinds)
    local tempArray = {}
    for k, v in pairs(tbl) do
        for _k,_v in pairs(json.decode(kinds)) do
            if v.kind == _v then
                table.insert(tempArray, v)
                break
            end
        end
        
    end
    local start = (page - 1) * size + 1
    local endPage = page * size
    local result = {};
    for i = start, endPage do
        if tempArray[i] then
            table.insert(result, tempArray[i])
        else
            break
        end
    end
    return result;
end

return {
    createEvent = createEvent,
    event = event,
    filters = filters,
    fetch = fetch,
}
