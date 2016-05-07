module Niancat

export NiancatHandler, on_reply, on_event, on_error, create_bot

using DandelionSlack
import DandelionSlack: RTMHandler, on_reply, on_event, on_error

include("types.jl")
include("interfaces.jl")
include("logic.jl")
include("dictionary.jl")
include("members.jl")
include("responder.jl")
include("command_parser.jl")
include("word_filter.jl")

#
# NiancatHandler is the main type of this entire bot. It integrates the command parser, logic, and
# responder.
#
type NiancatHandler <: RTMHandler
    members::Members
    logic::AbstractLogic
    responder::Nullable{AbstractResponder}
    main_channel_id::ChannelId

    function NiancatHandler(
        rtm_client::AbstractRTMClient,
        members::AbstractMembers,
        words::AbstractWordDictionary,
        main_channel_id::ChannelId)

        new(members,
            Logic(words, members),
            Nullable{AbstractResponder}(Responder(rtm_client, main_channel_id)),
            main_channel_id)
    end

    function NiancatHandler(members::AbstractMembers,
                            words::AbstractWordDictionary,
                            main_channel_id::ChannelId)
        new(members, Logic(words, members), Nullable(), main_channel_id)
    end
end

function on_create(h::NiancatHandler, client::AbstractRTMClient)
    h.responder = Nullable{AbstractResponder}(client, h.main_channel_id)
end

function on_event(h::NiancatHandler, event::MessageEvent)
    if !isnull(h.responder)
        command = parse_command(event)
        response = handle(h.logic, command)
        respond(h.responder, response)
    end
end

function on_event(h::NiancatHandler, ::HelloEvent)
    users_response = makerequest(UsersList(Nullable{Int}()), requests)
    for u in users_response.users
        add(h.members, u)
    end
end

# Catch all other events we don't care about.
on_error(h::NiancatHandler, reason::Symbol, text::UTF8String) = nothing
on_reply(h::NiancatHandler, id::Int64, event::Event) = nothing
on_event(h::NiancatHandler, event::Event) = nothing

#
# Initialize the bot by reading the dictionary.
#

function create_bot(dictionary_stream::IO, token::UTF8String, main_channel_id::ChannelId;
                    connector=DandelionSlack.rtm_connect)
end

end # module
