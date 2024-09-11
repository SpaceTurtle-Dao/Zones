local ao = require('ao')
local json = require('json');

function event(data)
    local _event = json.decode(data);
    return _event
end

function filters(value)
    local filters = json.decode(value)
    return filters
end


return {
    event = event,
    filters = filters,
}
