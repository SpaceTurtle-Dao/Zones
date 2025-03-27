local json = require('json');
local bint = require('.bint')(256)
local utils = require(".utils")
-- Registry for managing zones
Zones = Zones or {}

-- Handler for registering a zone (msg.From as Register)
Handlers.add("Register", Handlers.utils.hasMatchingTag("Action", "Register"), function(msg)
  local registeringZone = msg.From                        -- Zone ID is msg.From
  local spec = msg.Data and json.decode(msg.Data) or {}   -- Zone spec from Data
  Zones[registeringZone] = {
    spec = spec,                                          -- e.g., { "type": "hub", "kinds": [1] }
    registeredAt = msg.Timestamp
  }
  ao.send({
    Target = msg.From,
    Data = "Successfully registered zone: " .. registeringZone
  })
end
)

-- Handler for querying registered zones with filtering and paging
Handlers.add("GetZones", Handlers.utils.hasMatchingTag("Action", "GetZones"), function(msg)
  local kind = msg.Kind                    -- Filter by zone type (e.g., "hub")
  local filters = msg.Filters and json.decode(msg.Filters) or {}
  local limit = tonumber(msg.Limit) or 100 -- Default page size
  local offset = tonumber(msg.Offset) or 0 -- Start index

  local zonesList = {}
  for zoneId, zoneData in pairs(Zones) do
    local spec = zoneData.spec
    local matches = true
    -- Filter by Kind (maps to spec.type)
    if kind then
      matches = matches and (spec.type == kind)
    end
    -- Filter on additional spec fields
    if filters.spec then
      for key, value in pairs(filters.spec) do
        matches = matches and (spec[key] == value)
      end
    end
    -- Filter on registeredAt
    if filters.minRegisteredAt then
      matches = matches and (tonumber(zoneData.registeredAt) >= filters.minRegisteredAt)
    end
    if matches then
      table.insert(zonesList, {
        id = zoneId,
        spec = spec,
        registeredAt = zoneData.registeredAt
      })
    end
  end

  -- Sort by registeredAt (newest first) and apply paging
  table.sort(zonesList, function(a, b) return a.registeredAt > b.registeredAt end)
  local pagedList = {}
  for i = offset + 1, math.min(offset + limit, #zonesList) do
    table.insert(pagedList, zonesList[i])
  end

  ao.send({
    Target = msg.From,
    Data = json.encode(pagedList)
  })
end)

-- Expose the registry's own spec as a Zone
Handlers.add(
  "Info",
  Handlers.utils.hasMatchingTag("Action", "Info"),
  function(msg)
    local registrySpec = {
      type = "registry",
      description = "Registers and lists zones with their specs (self-registration via msg.From)",
      version = "0.1"
    }
    ao.send({
      Target = msg.From,
      Data = json.encode(registrySpec)
    })
  end
)
