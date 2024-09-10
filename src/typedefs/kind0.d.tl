global record Kind0
    id: string
    pubkey: string
    created_at: string
    kind: number
    tags: {{string}}
    content: Content
    sig: string
end

global record Content
    name: string
    about: string
    picture: string
    display_name: number
    website: string
    banner: string
    bot: string
end

return Kind0