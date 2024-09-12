--local Filter = require('filter')
local Event = require('event')
--local rxJson = require('json')
local systems = require('systems.systems')
require('database')

local function event(msg: Message)
    --creates and event and inserts it into the Events table
    assert(ao.env.Process.Owner == msg.From)
    local _event:Event = systems.createEvent(msg);
    table.insert(Events,_event)
    --Brodcast
    --[[for k,v in pairs(Subs) do
        ao.send({
            Target = v,
            Action = "Feed",
            Data = rxJson.encode(_event),
        }) 
    end]]--
end

return {
    event = event
}