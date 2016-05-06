export Responder, respond

import DandelionSlack: AbstractRTMClient

immutable Responder <: AbstractResponder
    client::AbstractRTMClient
    main_channel::ChannelId
end

send(r::Responder, channelId::ChannelId, text::UTF8String) =
    send_event(r.client, OutgoingMessageEvent(text, channelId))

macro response(response_type::Symbol, s::Expr)
    quote
        $(esc(:respond))(r::Responder, response::$response_type) =
            send(r, response.channel, $s)
    end
end

@response IncorrectSolutionResponse utf8("Ordet $(response.word) finns inte med i SAOL.")
@response CorrectSolutionResponse   utf8("Ordet $(response.word) är korrekt!")
@response NoPuzzleSetResponse utf8("Dagens nia är inte satt!")
@response InvalidPuzzleResponse utf8("$(response.puzzle) är inte giltig!")

respond(r::Responder, response::SolutionNotificationResponse) =
    send(r, r.main_channel, utf8("$(response.name) löste nian: $(response.hash)"))

respond(r::Responder, response::UnknownUserSolutionResponse) =
    send(r, r.main_channel, utf8("<@$(response.user)> löste nian, men är en okänd användare"))


function respond(r::Responder, response::GetPuzzleResponse)
    s = ""
    if response.solutions == 1
        s = utf8("$(response.puzzle)")
    else
        s = utf8("$(response.puzzle)\nDen har $(response.solutions) lösningar.")
    end
    send(r, response.channel, s)
end

function respond(r::Responder, response::SetPuzzleResponse)
    s = ""
    if response.solutions == 1
        s = utf8("Dagens nia är satt till $(response.puzzle)")
    else
        s = utf8("Dagens nia är satt till. $(response.puzzle)\nDen har $(response.solutions) lösningar.")
    end
    send(r, response.channel, s)
end

respond(r::Responder, ::IgnoredEventResponse) = nothing