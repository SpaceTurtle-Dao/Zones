local subscription_system = require('relay_systems.subscription_system')
local feed_system = require('relay_systems.feed_system')
require('database')

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
        feed_system.payedFeed(msg)
        return
    end
    if _type == "Subscribe" then
        subscription_system.subscribe(msg)
        return
    end
    ao.send({
        Target = msg.From,
        Quantity = msg.Tags.Quantity,
        Recipient = msg.Tags.Sender
    })
end  
  
--local function debitNotice(msg: Message)end

return {
    creditNotice = creditNotice
}