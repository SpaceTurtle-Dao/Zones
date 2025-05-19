
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

function event(msg)
  table.insert(RecentActivity, os.time())

  local myFollowList = getFollowList(State.Events, State.Owner)
  local isFollowing = utils.includes(msg.From, myFollowList)

  if msg.Kind == Kinds.FOLLOW then
    local newFollowList = {}
    for _, tag in ipairs(msg.Tags or {}) do
      if tag[1] == "p" then
        table.insert(newFollowList, tag[2])
      end
    end
    local isFollowingMe = utils.includes(State.Owner, newFollowList)
    if not isFollowingMe then
      State.Events = utils.filter(function(e)
        return not (e.Kind == Kinds.FOLLOW and e.From == msg.From)
      end, State.Events)
      return
    end
    table.insert(State.Events, msg)
    return
  end

  if msg.Kind == Kinds.DELETION then
    for _, tag in ipairs(msg.Tags or {}) do
      if tag[1] == "e" or tag[1] == "a" then
        local tombstone = nil
        State.Events = utils.filter(function(e)
          local match = e.Id == tag[2] and e.From == msg.From
          if match then
            tombstone = {
              Kind = Kinds.TOMBSTONE,
              Tags = {
                { "deleted-id", e.Id },
                { "deleted-kind", e.Kind },
                { "deleted-by", msg.From },
                { "deleted-author", e.From }
              },
              Data = msg.Content or "",
              Timestamp = msg.Timestamp or os.time()
            }
          end
          return not match
        end, State.Events)
        if tombstone then
          table.insert(State.Events, tombstone)
          if tombstoneBroadcastKinds[tombstone.Tags[2][2]] then
            broadcastToFollowers(tombstone)
          end
        end
      end
    end
    table.insert(State.Events, msg)
    return
  end

  if msg.From == State.Owner then
    broadcastToFollowers(msg)
    table.insert(State.Events, msg)
    return
  end

  if State.AllowedKinds[msg.Kind] then
    local shouldGossip = isFollowing and msg.Kind ~= Kinds.GOSSIP and msg.Signature and not hasSeenReference(msg.Signature)
    table.insert(State.Events, msg)
    if shouldGossip then
      local tags = {
        { "hub", "true" },
        { "received-from", msg.From },
        { "reference-signature", msg.Signature },
        { "referenced-kind", msg.Kind },
        { "Kind", Kinds.GOSSIP }
      }
      for _, tag in ipairs(msg.Tags or {}) do table.insert(tags, tag) end
      local gossipMsg = {
        Kind = Kinds.GOSSIP,
        Tags = tags,
        Data = "Gossip propagation for kind " .. msg.Kind
      }
      table.insert(State.Events, gossipMsg)
      broadcastToFollowers(gossipMsg)
    end
  end
end

Handlers.add("Event", function(msg)
  local isOwner = msg.From == State.Owner
  local following = getFollowList(State.Events, State.Owner)
  local isFollowed = utils.includes(msg.From, following)

  if isOwner or isFollowed then
    event(msg)
  end
end)

Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag("Action", "Credit-Notice"), function(msg)
  local from = msg.From
  local payloadStr = msg["X-Payload"]
  local amount = tonumber(msg.Amount or "0")
  if not payloadStr then return end
  local ok, payload = pcall(json.decode, payloadStr)
  if not ok or type(payload) ~= "table" then return end
  local kind = payload.Kind or getTag(payload.Tags, "kind")
  if not kind then return end
  local required = calculateDynamicFee(kind, from)
  if amount < required then return end
  payload.Tags = payload.Tags or {}
  table.insert(payload.Tags, { "paid", "true" })
  table.insert(payload.Tags, { "paid-amount", tostring(amount) })
  table.insert(payload.Tags, { "required-fee", tostring(required) })
  event(payload)
end)

Handlers.add("QueryFee", Handlers.utils.hasMatchingTag("Action", "QueryFee"), function(msg)
  local kind = getTag(msg.Tags, "kind")
  if not kind then return end
  local fee = calculateDynamicFee(kind, msg.From)
  ao.send({ Target = msg.From, Data = json.encode({ kind = kind, requiredFee = fee }) })
end)

Handlers.add("Config", Handlers.utils.hasMatchingTag("Action", "Config"), function(msg)
  if msg.From ~= State.Owner then return end
  local ok, body = pcall(json.decode, msg.Data or "{}")
  if not ok or type(body) ~= "table" then return end

  if body.FeePolicy then
    State.FeePolicy = body.FeePolicy
  end

  if body.AllowedKinds then
    State.AllowedKinds = body.AllowedKinds
  end
end)
