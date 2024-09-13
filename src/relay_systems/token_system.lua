local function req(msg)
    --subscribes to events from this relay
    if utils.toNumber(msg.Quantity) < utils.toNumber(SubscriptionCost) then
        --[[return funds and send message about insufficient funds]] --
        ao.send({
            Target = msg.From,
            Quantity = msg.Quantity,
            Recipient = msg.Sender
        })
        ao.send({
            Target = msg.Sender,
            Action = ao.id,
            Status = "400"
        })
        return
    end
    table.insert(Subs,msg.Sender)
    ao.send({
        Target = msg.Sender,
        Action = ao.id,
        Status = "200"
    })
    --local filters:{Filter} = systems.filters(msg.Tags.Filters);
    --local subscription_id = msg.Tags["subscription_id"]
end

local function payedFeed(msg)
    --pays relay to add event to feed since relay is not subscribed 
    --basically paying for attention
    if utils.toNumber(msg.Quantity) < utils.toNumber(FeedCost) then
        --[[return funds and send message about insufficient funds]]-- 
        ao.send({
        Target = msg.From,
        Quantity = msg.Quantity,
        Recipient = msg.Sender
        })
        return 
    end
    if not Subs[msg.From] then return end
    local _event = systems.event(msg.Event);
    table.insert(Feed,_event)
end

--local function debitNotice(msg: Message)end
