module Niancat

export NiancatHandler, on_reply, on_event, on_error

using DandelionSlack
import DandelionSlack: RTMHandler, on_reply, on_event, on_error

include("types.jl")
include("interfaces.jl")
include("logic.jl")
include("dictionary.jl")
include("members.jl")
include("responder.jl")
include("command_parser.jl")

type NiancatHandler <: RTMHandler
    logic::AbstractLogic
    responder::AbstractResponder

    function NiancatHandler(
        rtm_client::AbstractRTMClient,
        members::AbstractMembers,
        words::AbstractWordDictionary,
        main_channel_id::ChannelId)

        new(Logic(words, members), Responder(rtm_client, main_channel_id))
    end
end

function on_event(h::NiancatHandler, event::MessageEvent)
    command = parse_command(event)
    response = handle(h.logic, command)
    respond(h.responder, response)
end

# on error is called when there is a problem with receiving the message, such as invalid JSON.
# This is not an error sent by Slack, but an error caught in this code.
on_error(h::NiancatHandler, reason::Symbol, text::UTF8String) = nothing
on_reply(h::NiancatHandler, id::Int64, event::Event) = nothing
on_event(h::NiancatHandler, event::Event) = nothing

end # module
