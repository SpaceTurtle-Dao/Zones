local Event = require('event')
--local Filter = require('filter')
local systems = require('systems.systems')
require('database')
local utils = require('utils.utils')


local function profile(msg: Message)
    --sets the profile event
    assert(ao.env.Process.Owner == msg.From)
    local _event = systems.createEvent(msg);
    if _event.kind == 0 then 
      Profile = _event
    end
  end
  
  local function token(msg: Message)
    --sets the cost of a subscription
    assert(ao.env.Process.Owner == msg.From)
    Token = msg.Tags.Token
  end
  
  local function subscriptionCost(msg: Message)
    --sets the cost of a subscription
    assert(ao.env.Process.Owner == msg.From)
    utils.toNumber(msg.Tags.Cost)
    SubscriptionCost = msg.Tags.Cost
  end
  
  local function feedCost(msg: Message)
    --sets the cost of a subscription
    assert(ao.env.Process.Owner == msg.From)
    utils.toNumber(msg.Tags.Cost)
    SubscriptionCost = msg.Tags.Cost
  end
  
  local function feed(msg: Message)
    if not Subs[msg.From] then return end
    local _event = systems.event(msg.Data);
    table.insert(Feed,_event)
  end
  
  local function payedFeed(msg: Message)
    --pays relay to add event to feed since relay is not subscribed 
    --basically paying for attention
    if utils.toNumber(msg.Tags.Quantity) < utils.toNumber(FeedCost) then
      --[[return funds and send message about insufficient funds]]-- 
      ao.send({
        Target = msg.From,
        Quantity = msg.Tags.Quantity,
        Recipient = msg.Tags.Sender
      })
      return 
    end
    if not Subs[msg.From] then return end
    local _event = systems.event(msg.Tags.Event);
    table.insert(Feed,_event)
  end
  
  local function event(msg: Message)
    --creates and event and inserts it into the Events table
    assert(ao.env.Process.Owner == msg.From)
    local _event:Event = systems.createEvent(msg);
    table.insert(Events,_event)
    --Brodcast
  end
  
  
  local function subscribe(msg: Message)
    --subscribes to events from this relay
    if utils.toNumber(msg.Tags.Quantity) < utils.toNumber(SubscriptionCost) then
      --[[return funds and send message about insufficient funds]]-- 
      ao.send({
        Target = msg.From,
        Quantity = msg.Tags.Quantity,
        Recipient = msg.Tags.Sender
      })
      return 
    end
    if not Subscriptions[msg.Tags.Sender] then Subscriptions[msg.Tags.Sender] = "0" end
    local quantity = Subscriptions[msg.Tags.Sender];
    Subscriptions[msg.Tags.Sender] = utils.add(quantity, msg.Tags.Quantity)
    
    --local filters:{Filter} = systems.filters(msg.Tags.Filters);
    --local subscription_id = msg.Tags["subscription_id"]
  end
  
  local function close(msg: Message)
    --removes relay from subscriptions and returns any remaining balance
    if not Subscriptions[msg.Tags.Sender] then Subscriptions[msg.Tags.Sender] = "0" end
    local quantity = Subscriptions[msg.Tags.Sender];
    if utils.toNumber(quantity) <= 0 then return end
    --return funds and set balance to 0
    Subscriptions[msg.From] = "0"
  end
  
  local function withdraw(msg: Message)
    --Withdraws Tokens
    assert(ao.env.Process.Owner == msg.From)
    ao.send({
      Target = msg.Tags.Token,
      Quantity = msg.Tags.Quantity,
      Recipient = msg.Tags.Recipient
    })
  end

  local function creditNotice(msg: Message)
    if msg.From ~= Token then
      --[[return funds and send message about unsupported token]]--
      ao.send({
        Target = msg.From,
        Quantity = msg.Tags.Quantity,
        Recipient = msg.Tags.Sender
      })
      return
    end
    if not msg.Tags["X-Type"] then 
      ao.send({
        Target = msg.From,
        Quantity = msg.Tags.Quantity,
        Recipient = msg.Tags.Sender
      })
      return
    end
  
    local _type = msg.Tags["X-Type"]
  
    if _type == "Feed" then 
      payedFeed(msg)
      return
    end
    if _type == "Subscribe" then
      subscribe(msg)
      return
    end
    ao.send({
      Target = msg.From,
      Quantity = msg.Tags.Quantity,
      Recipient = msg.Tags.Sender
    })
  end 

  return {
    profile = profile,
    token = token,
    subscriptionCost = subscriptionCost,
    feedCost = feedCost,
    feed = feed,
    payedFeed = payedFeed,
    event = event,
    subscribe = subscribe,
    close = close,
    withdraw = withdraw,
    creditNotice = creditNotice
  }