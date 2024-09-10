local record NIP01
    record Kind1
        id: string
        pubkey: string
        created_at: string
        kind: number
        tags: {{string}}
        content: string
        sig: string
    end
    
    record Kind0
        id: string
        pubkey: string
        created_at: string
        kind: number
        tags: {{string}}
        content: Content
        sig: string
    end
    
    record Content
        name: string
        about: string
        picture: string
        display_name: number
        website: string
        banner: string
        bot: string
    end
end

return NIP01