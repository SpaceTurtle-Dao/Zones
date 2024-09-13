-- Initialize global variables
local ao = require('ao')
local json = require('json');
local bint = require('.bint')(256)
local utils = require(".utils")

-- Utils helper functions
Utils = {
    add = function(a, b)
        return tostring(bint(a) + bint(b))
    end,
    subtract = function(a, b)
        return tostring(bint(a) - bint(b))
    end,
    toBalanceValue = function(a)
        return tostring(bint(a))
    end,
    toNumber = function(a)
        return tonumber(a)
    end
}

Variant = "0.0.1"
Token = "WPyLgOqELOyN_BoTNdeEMZp5sz3RxDL19IGcs3A9IPc" -- AO or wAR token currently set to swappy tokens for testing
RelayCost = "1000000"
RelayModule = ""

if not Relays then Relays = {} end
if not RelayRequest then RelayRequest = {} end

local function fetch(tbl, page, size)
    local start = (page - 1) * size + 1
    local endPage = page * size
    local result = {};
    for i = start, endPage do
        if tbl[i] then
            table.insert(result, tbl[i])
        else
            break
        end
    end
    return result;
end

Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(msg)
    ao.send({
        Target = msg.From,
        Relays = #Relays,
        RelayRequest = #RelayRequest,
        RelayCost = RelayCost,
        Token = Token,
        Variant = Variant
    })
end)

Handlers.add('Relay', Handlers.utils.hasMatchingTag('Action', 'Relay'), function(msg)
    if Relays[msg.RelayOwner]  then
        ao.send({
            Target = msg.From,
            Relay = Relays[msg.RelayOwner],
        }) 
    end
end)

Handlers.add('Relays', Handlers.utils.hasMatchingTag('Action', 'Relays'), function(msg)
    local page = Utils.toNumber(msg.Page)
    local size = Utils.toNumber(msg.Size)

    ao.send({
        Target = msg.From,
        Relays = json.encode(fetch(Relays, page, size)),
    }) 
end)

Handlers.add('Request', Handlers.utils.hasMatchingTag('Action', 'Request'), function(msg)
    ao.spawn(RelayModule, {})
    table.insert(RelayRequest,msg.From)
    ao.send({
        Target = msg.From,
        Text = "Your Awesome",
    });
end)

Handlers.add('Spawned', Handlers.utils.hasMatchingTag('Action', 'Spawned'), function(msg)
    assert(msg.From == ao.id, "Not Authorized");
    if #RelayRequest < 1 then return end
    local _owner = table.remove(RelayRequest,1)
    Relays[_owner] = msg.Process
    ao.send({
        Target = msg.Process,
        Action = "Eval",
        Data = RelayModule,
    });
end)


Handlers.add('Activate', Handlers.utils.hasMatchingTag('Action', 'Activate'), function(msg)
    if RelayRequest[msg.From] then
        local _owner = RelayRequest[msg.From];
        ao.send({
            Target = msg.Process,
            Action = "Eval",
            Data = "Owner = ".._owner,
        }); 
    end
end)