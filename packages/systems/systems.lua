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

function fetch(tbl, page, size)
    local tempArray = {}
    for k, v in pairs(tbl) do
        table.insert(tempArray, v)
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
    event = event,
    filters = filters,
}
