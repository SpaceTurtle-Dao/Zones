json = require("json")

spawnedHubs = spawnedHubs or {}
spawnedHubsWithTables = spawnedHubsWithTables or {}

Handlers.add("SpawnHub", Handlers.utils.hasMatchingTag("Action", "SpawnHub"), function(msg)
	local data = json.decode(msg.Data)
	local name = data.name

	local response = ao.spawn(ao.env.Module.Id, {
		["On-Boot"] = "3Bn4Ddq-SWp_FQY9Ko7VVu4Bo_JQiKRvH1xVLST0IUQ",
		["Name"] = name,
	}).receive()

	spawnedHubs[name] = response.Process
	spawnedHubsWithTables[name] = response

	print(response.Process)
end)
