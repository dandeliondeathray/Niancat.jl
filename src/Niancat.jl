module Niancat

export NiancatHandler, on_reply, on_event, on_error

using DandelionSlack
import DandelionSlack: RTMHandler, on_reply, on_event, on_error, on_connect, on_disconnect,
                       AbstractRTMClient

include("types.jl")
include("interfaces.jl")
include("dictionary.jl")
include("unsolutions.jl")
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
    responder::AbstractResponder
    main_channel_id::ChannelId
    token::Token

    function NiancatHandler(
        client::AbstractRTMClient,
        members::AbstractMembers,
        words::AbstractWordDictionary,
        main_channel_id::ChannelId,
        token::Token)

        handler = new(members, Logic(words, members), Responder(client, main_channel_id),
                      main_channel_id, token)
        attach(client, handler)
        handler
    end
end

function on_event(h::NiancatHandler, event::MessageEvent)
    command = parse_command(event)
    response = handle(h.logic, command)
    respond(h.responder, response)
end

function on_event(h::NiancatHandler, ::HelloEvent)
    println("Hello event received. Retrieving members...")
    retrieve_user_list(h.members, h.token)
end

# Catch all other events we don't care about.
on_error(h::NiancatHandler, e::EventError) = println("on_error: $e")
on_reply(h::NiancatHandler, id::Int, event::Event) = nothing
on_event(h::NiancatHandler, event::Event) = nothing
on_connect(h::NiancatHandler) = println("Niancat connected.")
on_disconnect(h::NiancatHandler) = println("Niancat disconnected.")

end # module
