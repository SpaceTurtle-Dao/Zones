local Event = require('event')
local Filter = require('filter')

-- this file only creates type definitions for the lua package
local systems = {}

global record SystemsModule
    event: function(value: string) : Event
    filters: function(value: string) : {Filter}
    fetch: function(tbl:{Event}, page:number, size:number) :{Event}
end

-- Assign the module type
return systems as SystemsModule