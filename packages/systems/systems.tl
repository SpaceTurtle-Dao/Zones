local Event = require('event')
local Filter = require('filter')

-- this file only creates type definitions for the lua package
local systems = {}

global record SystemsModule
    event: function(msg: Message) : Event
    filters: function(msg: Message) : {Filter}
end

-- Assign the module type
return systems as SystemsModule