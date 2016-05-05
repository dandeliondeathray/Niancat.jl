main_channel_id = ChannelId("C0123")

type TestEvent
    has_texts::Vector{UTF8String}
    channel::Nullable{ChannelId}
    user::Nullable{UserId}

    TestEvent(xs...; channel=Nullable{ChannelId}(), user=Nullable{UserId}()) =
        new(xs.., channel, user)
end

type ResponderTest
    description::AbstractString
    response::AbstractResponse
    expected::Vector{TestEvent}
end

responder_tests = [
    ResponderTest(
        SolutionNotificationResponse(SlackName("erike"), utf8("abcdef")),
        [TestEvent("erike", "abcdef"; channel=main_channel_id)]),

    ResponderTest(
        IncorrectSolutionResponse(UserId("U0"), Word("FOO")),
        [TestEvent("FOO"; user=UserId("U0"))]
]

type FakeRTMClient <: AbstractRTMClient
    messages::Vector{OutgoingEvent}
end

send_event(c::FakeRTMClient, event::OutgoingEvent) = append!(c.messages, event)

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

                if !isnull(test_event.channel)
                    @fact message.channel --> test_event.channel
                end

                if !isnull(test_event.user)
                    @fact message.user --> test_event.user
                end

                for text in test_event.has_texts
                    @fact contains(message.text, text) --> true
                end
            end
        end
    end
end