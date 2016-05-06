main_channel_id = ChannelId("C0123")

import DandelionSlack: OutgoingEvent, OutgoingMessageEvent, AbstractRTMClient, send_event

type TestEvent
    channel::ChannelId
    has_texts::Vector{UTF8String}

    TestEvent(channelId::ChannelId, xs...) = new(channelId, [xs...])
end

type ResponderTest
    description::AbstractString
    response::AbstractResponse
    expected::Vector{TestEvent}
end

responder_tests = [
    ResponderTest(
        "Solution notification response to main channel",
        SolutionNotificationResponse(SlackName("erike"), utf8("abcdef")),
        [TestEvent(main_channel_id, "erike", "abcdef")]),

    ResponderTest(
        "Incorrect solution response to user",
        IncorrectSolutionResponse(ChannelId("D0"), Word("FOO")),
        [TestEvent(ChannelId("D0"), "FOO")]),

    ResponderTest(
        "Correct solution response to user",
        CorrectSolutionResponse(ChannelId("D0"), Word("FOO")),
        [TestEvent(ChannelId("D0"), "FOO")]),
]

type FakeRTMClient <: AbstractRTMClient
    messages::Vector{OutgoingEvent}

    FakeRTMClient() = new([])
end

send_event(c::FakeRTMClient, event::OutgoingEvent) = push!(c.messages, event)

function take_message!(c::FakeRTMClient)
    @fact c.messages --> not(isempty)
    ev = shift!(c.messages)
    @fact typeof(ev) --> OutgoingMessageEvent
    ev
end

facts("Responder") do
    for t in responder_tests
        context(t.description) do
            client = FakeRTMClient()
            responder = Responder(client, main_channel_id)

            respond(responder, t.response)

            for test_event in t.expected
                message = take_message!(client)

                @fact message.channel --> test_event.channel

                for text in test_event.has_texts
                    @fact contains(message.text, text) --> true
                end
            end
        end
    end
end