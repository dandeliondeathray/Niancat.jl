module Niancat

export NiancatHandler, on_reply, on_event, on_error, on_create, create_bot

using DandelionSlack
import DandelionSlack: RTMHandler, on_reply, on_event, on_error

include("types.jl")
include("interfaces.jl")
include("dictionary.jl")
include("logic.jl")
include("members.jl")
include("responder.jl")
include("command_parser.jl")
include("word_filter.jl")

#
# NiancatHandler is the main type of this entire bot. It integrates the command parser, logic, and
# responder.
#
type NiancatHandler <: RTMHandler
    members::AbstractMembers
    logic::AbstractLogic
    responder::Nullable{AbstractResponder}
    main_channel_id::ChannelId
    token::Token

    function NiancatHandler(
        members::AbstractMembers,
        words::AbstractWordDictionary,
        main_channel_id::ChannelId,
        token::Token)

        new(members,
            Logic(words, members),
            Nullable{AbstractResponder}(),
            main_channel_id,
            token)
    end
end

function on_create(h::NiancatHandler, client::AbstractRTMClient)
    h.responder = Nullable{AbstractResponder}(Responder(client, h.main_channel_id))
end

function on_event(h::NiancatHandler, event::MessageEvent)
    command = parse_command(event)
    response = handle(h.logic, command)
    if !isnull(h.responder)
        respond(get(h.responder), response)
    end
end

function on_event(h::NiancatHandler, ::HelloEvent)
    println("Hello event received. Niancat is connected. Retrieving members...")
    retrieve_user_list(h.members, h.token)
end

# Catch all other events we don't care about.
on_error(h::NiancatHandler, reason::Symbol, text::UTF8String) = nothing
on_reply(h::NiancatHandler, id::Int64, event::Event) = nothing
on_event(h::NiancatHandler, event::Event) = nothing

#
# Initialize the bot by reading the dictionary.
#

end # module
