export Unsolutions, unsolution, unsolution_notification

type Unsolutions <: AbstractUnsolutions
    entries::Dict{UserId, UnsolutionEntry}

    Unsolutions() = new(Dict{UserId, UnsolutionEntry}())
end

function unsolution(r::Unsolutions, command::SetUnsolutionCommand)
    # This defaults to a newly constructed entry with the specified channel as the response channel.
    # This means that if the user, hypothetically, was to set a unsolution from two different
    # channels, then the bot will respond in the first of those channels, since that's the one where
    # this default construction of UnsolutionEntry is done.
    entry = get(r.entries, command.user, UnsolutionEntry(command.channel))
    push!(entry.texts, command.text)
    r.entries[command.user] = entry
    SetUnsolutionResponse(command.channel, command.text)
end

function unsolution(r::Unsolutions, command::GetUnsolutionsCommand)
    texts = []
    if haskey(r.entries, command.user)
        # When there are unsolutions, list them in the private channel specified in the entry.
        entry = r.entries[command.user]
        return GetUnsolutionsResponse(entry.channel, entry.texts)
    end

    # When there are no unsolutions, list them in then channel the command came from, even if that is
    # a public channel. Since there are no unsolutions, there's nothing to spoil.
    GetUnsolutionsResponse(command.channel, texts)
end


function unsolution_notification(r::Unsolutions)
    user_unsolutions = Dict{UserId, UnsolutionList}([
        u => entry.texts
        for (u, entry) in r.entries
    ])
    empty!(r.entries)
    UnsolutionNotificationResponse(user_unsolutions)
end