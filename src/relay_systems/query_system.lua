local function fetch(tbl, page, size, kinds)
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

local function fetchFeed(msg)
    local page = utils.toNumber(msg.Page)
    local size = utils.toNumber(msg.Size)
    local results = fetch(Feed, page, size, msg.Kinds)
    ao.send({
        Target = msg.From,
        Data = json.encode(results)
    })
end

local function fetchEvents(msg)
    local page = utils.toNumber(msg.Page)
    local size = utils.toNumber(msg.Size)
    local results = fetch(Events, page, size, msg.Kinds)
    ao.send({
        Target = msg.From,
        Data = json.encode(results)
    })
end

return {
    info = info,
    fetchFeed = fetchFeed,
    fetchEvents = fetchEvents,
    fetchSubs = fetchSubs,
    fetchSubscriptions = fetchSubscriptions,
}