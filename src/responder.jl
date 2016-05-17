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

function prettify(p::Puzzle)
    s = [p...]
    utf8(s[1:3]) * " " * utf8(s[4:6]) * " " * utf8(s[7:9])
end

help_text = """
"Dagens nia" är ett ordpussel från Svenska Dagbladet. Varje dag får man nio bokstäver, och ska hitta
vilket svenskt ord man kan konstruera med hjälp av dessa bokstäver.
Boten 'niancat' hjälper dig att lösa nian genom att kontrollera om ord finns med i SAOL eller inte,
och att bokstäverna matchar dagens nia. Om du skriver in ett lösningsförslag i ett privat-meddelande
till boten så kommer den säga till om ordet är korrekt, och i sådana fall automatiskt notifiera
kanalen om att du hittat en lösning.

Innan du har löst dagens nia är det bra om du inte skriver in lösningsförslag i kanalen, då det är
möjligt att du är nära utan att veta om det, och därmed i praktiken löser den åt andra. När du löst
den kan du skriva lösningsförslag i kanalen, men håll dig gärna till ord som inte är nära den
riktiga lösningen.

Kommandon:
    !setnian <pussel>   Sätt nian.
    !nian               Visa nian.
    !unsolution <text>  Sätt en olösning, att visas när nästa nian sätts.
    !unsolutions        Visa alla mina olösning. Svar, om det finns, visas i en privat kanal.
    !helpnian           Visa denna hjälptext.

Alla dessa kommandon kan man köra både i kanalen och i privat-meddelande till tiancat.
"""

quote_delim = "\n> "
@response CorrectSolutionResponse   utf8("Ordet $(response.word) är korrekt!")
@response NoPuzzleSetResponse utf8("Dagens nia är inte satt!")
@response InvalidPuzzleResponse utf8("$(response.puzzle) är inte giltig!")
@response HelpResponse utf8(help_text)
@response SetUnsolutionResponse utf8("Olösning satt: $(response.text)")

respond(r::Responder, response::SolutionNotificationResponse) =
    send(r, r.main_channel, utf8("$(response.name) löste nian: $(response.hash)"))

respond(r::Responder, response::UnknownUserSolutionResponse) =
    send(r, r.main_channel, utf8("<@$(response.user)> löste nian, men är en okänd användare"))

function respond(r::Responder, response::IncorrectSolutionResponse)
    # @response IncorrectSolutionResponse utf8("Ordet $(response.word) finns inte med i SAOL.")
    response_text = utf8("")
    if response.reason == :not_in_dictionary
        text = "Ordet $(response.word) finns inte med i SAOL."
    elseif response.reason == :not_nine_characters
        text = "Ordet $(response.word) är inte nio tecken långt."
    else
        text = "Ordet $(response.word) är inkorrekt, men av oklara skäl."
    end

    send(r, response.channel, utf8(text))
end

function respond(r::Responder, response::NonMatchingWordResponse)
    text = utf8("Ordet $(response.word) matchar inte dagens nia $(response.puzzle).")

    if response.too_many != utf8("")
        text = text * utf8(" För många $(response.too_many).")
    end

    if response.too_few != ""
        text = text * utf8(" För få $(response.too_few).")
    end

    send(r, response.channel, text)
end

function respond(r::Responder, response::GetPuzzleResponse)
    s = ""
    puzzle = prettify(response.puzzle)
    if response.solutions == 1
        s = utf8("$(puzzle)")
    else
        s = utf8("$(puzzle)\nDen har $(response.solutions) lösningar.")
    end
    send(r, response.channel, s)
end

function respond(r::Responder, response::SetPuzzleResponse)
    s = ""
    puzzle = prettify(response.puzzle)
    if response.solutions == 1
        s = utf8("Dagens nia är satt till $(puzzle)")
    else
        s = utf8("Dagens nia är satt till $(puzzle)\nDen har $(response.solutions) lösningar.")
    end
    send(r, response.channel, s)
end

respond(r::Responder, ::IgnoredEventResponse) = nothing

function respond(r::Responder, c::CompositeResponse)
    for x in c
        respond(r, x)
    end
end

function respond(r::Responder, response::InvalidCommandResponse)
    if response.reason == :unknown
        send(r, response.channel, utf8("Okänt kommando"))
    else
        send(r, response.channel, utf8("Fel: $(response.reason)"))
    end
end

function respond(r::Responder, response::UnsolutionNotificationResponse)
    header = [utf8("*Olösningar*")]
    unsolutions = [
        utf8("\n<@$(user)>\n> $(join(unsolutions, quote_delim))")
        for (user, unsolutions) in response.entries
    ]

    send(r, r.main_channel, join([header; unsolutions]))
end

function respond(r::Responder, response::GetUnsolutionsResponse)
    text = utf8("Inga olösningar sparade.")
    if !isempty(response.texts)
        text = utf8("Olösningar:\n> $(join(response.texts, quote_delim))")
    end

    send(r, response.channel, text)
end
