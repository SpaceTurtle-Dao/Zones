local record Filter
    ids: {string}
    authors: {string}
    kinds: {string}
    tags: {string:{string}}
    since: string
    _until: string
    limit: number   
end

return Filter

--[[{
    "ids": <a list of event ids>,
    "authors": <a list of lowercase pubkeys, the pubkey of an event must be one of these>,
    "kinds": <a list of a kind numbers>,
    "#<single-letter (a-zA-Z)>": <a list of tag values, for #e — a list of event ids, for #p — a list of pubkeys, etc.>,
    "since": <an integer unix timestamp in seconds. Events must have a created_at >= to this to pass>,
    "until": <an integer unix timestamp in seconds. Events must have a created_at <= to this to pass>,
    "limit": <maximum number of events relays SHOULD return in the initial query>
}]]--