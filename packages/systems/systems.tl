local Event = require('event')
local Filter = require('filter')

-- this file only creates type definitions for the lua package
local systems = {}

global record SystemsModule
    createEvent: function(value: Message) : Event
    event: function(value: string) : Event
    filters: function(value: string) : {Filter}
    fetch: function(tbl:{Event}, page:number, size:number, kinds:string) :{Event}
end

-- Assign the module type
return systems as SystemsModule