export Responder, respond

import DandelionSlack: AbstractRTMClient

immutable Responder <: AbstractResponder
    client::AbstractRTMClient
    main_channel::ChannelId
end

send(r::Responder, channelId::ChannelId, text::UTF8String) =
    send_event(r.client, OutgoingMessageEvent(text, channelId))

respond(r::Responder, response::SolutionNotificationResponse) =
    send(r, r.main_channel, utf8("$(response.name) löste nian: $(response.hash)"))

macro response(response_type::Symbol, s::Expr)
    quote
        $(esc(:respond))(r::Responder, response::$response_type) =
            send(r, response.channel, $s)
    end
end

@response IncorrectSolutionResponse utf8("Ordet $(response.word) finns inte med i SAOL.")
@response CorrectSolutionResponse   utf8("Ordet $(response.word) är korrekt!")