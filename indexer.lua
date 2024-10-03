-- Initialize global variables
--local ao = require('ao')
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
RelayModule = "bkjb55i07GUCUSWROtKK4HU1mBS_X0TyH3M5jMV6aPg"
RelayCount = 0

if not Relay_Lua_Module then Relay_Lua_Module = "" end
if not Relays then Relays = {} end
if not RelayRequest then RelayRequest = {} end

local function fetch(tbl, page, size)
    local temp = {}
    for k, v in pairs(tbl) do
        local obj = {
            owner = k,
            relay = v
        }
        table.insert(temp,obj)
    end
    local start = (page - 1) * size + 1
    local endPage = page * size
    local result = {};
    for i = start, endPage do
        if temp[i] then
            table.insert(result, temp[i])
        else
            break
        end
    end
    return result;
end

Handlers.add('Info', Handlers.utils.hasMatchingTag('Action', 'Info'), function(msg)
    local _info = {
        Variant = Variant,
        RelayModule = RelayModule,
        RelayCount = RelayCount
    }
    ao.send({
        Target = msg.From,
        Data = json.encode(_info)
    }) 
end)

Handlers.add('Relay-Module', Handlers.utils.hasMatchingTag('Action', 'Relay-Module'), function(msg)
    ao.send({
        Target = msg.From,
        Data = Relay_Lua_Module
    }) 
end)

Handlers.add('DeleteRelays', Handlers.utils.hasMatchingTag('Action', 'DeleteRelays'), function(msg)
    Relays = {}
    RelayRequest = {}
end)

Handlers.add('Relay', Handlers.utils.hasMatchingTag('Action', 'Relay'), function(msg)
    if Relays[msg._Owner]  then
        ao.send({
            Target = msg.From,
            Data = Relays[msg._Owner],
        }) 
    end
end)

Handlers.add('Relays', Handlers.utils.hasMatchingTag('Action', 'Relays'), function(msg)
    local page = Utils.toNumber(msg.Page)
    local size = Utils.toNumber(msg.Size)

    ao.send({
        Target = msg.From,
        Data = json.encode(fetch(Relays, page, size)),
    }) 
end)

Handlers.add('Request', Handlers.utils.hasMatchingTag('Action', 'Request'), function(msg)
    if Relays[msg.From] then
        local relay = Relays[msg.From]
        ao.send({
            Target = msg.From,
            Relay = relay,
            Data = "Looks like you already own a Relay "..relay
        })
        return
    end
    ao.spawn(RelayModule, {})
    table.insert(RelayRequest,msg.From)
    ao.send({
        Target = msg.From,
        Data = "Your Awesome",
    });
end)

Handlers.add('Spawned', Handlers.utils.hasMatchingTag('Action', 'Spawned'), function(msg)
    assert(msg.From == ao.id, "Not Authorized");
    if #RelayRequest < 1 then return end
    local _owner = table.remove(RelayRequest,1)
    Relays[_owner] = msg.Process
    RelayCount = RelayCount + 1
    ao.send({
        Target = msg.Process,
        Action = "Eval",
        Data = Relay_Lua_Module,
    });
end)

Handlers.add('Activate', Handlers.utils.hasMatchingTag('Action', 'Activate'), function(msg)
    for k, v in pairs(Relays) do
        if v == msg.From then
            ao.send({
                Target = msg.From,
                Action = "SetOwner",
                _Owner = k
            });
        end
    end
end)

Handlers.add('SetRelay', Handlers.utils.hasMatchingTag('Action', 'SetRelay'), function(msg)
    Relays[msg.From] = msg.Relay
end)


Handlers.add('Relay_Lua_Module', Handlers.utils.hasMatchingTag('Action', 'Relay_Lua_Module'), function(msg)
    --assert(msg.From == Owner) --[[REMOVE COMMENTS BEFORE GOING LIVE!!!!!!!]]
    if msg.Data then
        Relay_Lua_Module = msg.Data
    end
end)