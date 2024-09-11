local Event = require('event')
--local Filter = require('filter')
local systems = require('systems.systems')
require('database')

local function event(msg: Message)
    --creates and event and inserts it into the Events table
    assert(ao.env.Process.Owner == msg.From)
    local _event:Event = systems.createEvent(msg);
    table.insert(Events,_event)
    --Brodcast
end

return {
    event = event
}