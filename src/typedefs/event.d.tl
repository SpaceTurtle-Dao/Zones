local record Event
    id: string
    pubkey: string
    created_at: string
    kind: number
    tags: {{string}}
    content: string
    sig: string
end

return Event