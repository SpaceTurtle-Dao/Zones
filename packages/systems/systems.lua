local ao = require('ao')
local json = require('json');

function event(msg)
    local _event = json.decode(msg.Data);
    return _event
end

function filters(msg)
    local filters = json.decode(msg.Data)
    return filters
end


return {
    event = event,
    filters = filters,
}
