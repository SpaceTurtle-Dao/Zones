
-- Velocity Hub (VIP-08 ready) - 2025-05-19T12:48 +07:00

local json = require('json')
local bint = require('.bint')(256)
local utils = require(".utils")

Kinds = {
  PROFILE_UPDATE = "0",
  NOTE = "1",
  FOLLOW = "3",
  DELETION = "5",
  WRAPPED_SEAL = "6",
  REACTION = "7",
  GOSSIP = "1000",
  TOMBSTONE = "9001"
}

State.FeePolicy = State.FeePolicy or {
  base = {
    [Kinds.NOTE] = 0.05,
    [Kinds.WRAPPED_SEAL] = 0.1,
    [Kinds.PROFILE_UPDATE] = 0.01,
    [Kinds.REACTION] = 0.02
  },
  scaleFactor = 1000,
  spikeEnabled = true,
  spikeWindow = 60,
  spikeScale = 60
}

State.AllowedKinds = State.AllowedKinds or {
  [Kinds.NOTE] = true,
  [Kinds.WRAPPED_SEAL] = true,
  [Kinds.PROFILE_UPDATE] = true,
  [Kinds.GOSSIP] = true,
  [Kinds.REACTION] = true
}

local tombstoneBroadcastKinds = {
  [Kinds.PROFILE_UPDATE] = true,
  [Kinds.NOTE] = true,
  [Kinds.WRAPPED_SEAL] = true,
  [Kinds.REACTION] = true
}

State = {
  Events = Events or {},
  Owner = Owner,
  Spec = {
    type = "hub",
    description = "Social message hub",
    version = "0.1"
  }
}

local RecentActivity = {}

local function slice(tbl, start_idx, end_idx)
  local new_table = {}
  table.move(tbl, start_idx or 1, end_idx or #tbl, 1, new_table)
  return new_table
end

local function getTag(tags, key)
  for _, tag in ipairs(tags or {}) do
    if tag[1] == key then return tag[2] end
  end
end

local function hasSeenReference(sig)
  for _, e in ipairs(State.Events) do
    if e.Kind == Kinds.GOSSIP and getTag(e.Tags, "reference-signature") == sig then
      return true
    end
  end
end

local function getFollowList(events, from)
  for i = #events, 1, -1 do
    local e = events[i]
    if e.Kind == Kinds.FOLLOW and e.From == from then
      local list = {}
      for _, tag in ipairs(e.Tags or {}) do
        if tag[1] == "p" then table.insert(list, tag[2]) end
      end
      return list
    end
  end
  return {}
end

local function getFollowers(events, pubkey)
  local followers = {}
  for _, e in ipairs(events) do
    if e.Kind == Kinds.FOLLOW then
      for _, tag in ipairs(e.Tags or {}) do
        if tag[1] == "p" and tag[2] == pubkey then
          table.insert(followers, e.From)
          break
        end
      end
    end
  end
  return followers
end

local function broadcastToFollowers(msg)
  for _, f in ipairs(getFollowers(State.Events, State.Owner)) do
    ao.send({ Target = f, Action = "Event", Data = msg.Data, Tags = msg.Tags })
  end
end

local function calculateDynamicFee(kind, from)
  local base = State.FeePolicy.base[kind] or 0
  if from == State.Owner then return base end

  local volumeFactor = #State.Events / (State.FeePolicy.scaleFactor or 1000)

  local spikeFactor = 0
  if State.FeePolicy.spikeEnabled then
    local now = os.time()
    local window = State.FeePolicy.spikeWindow or 60
    local scale = State.FeePolicy.spikeScale or 60

    RecentActivity = utils.filter(function(ts)
      return ts > now - window
    end, RecentActivity)

    spikeFactor = #RecentActivity / scale
  end

  local multiplier = 1 + volumeFactor + spikeFactor
  return base * multiplier
end
