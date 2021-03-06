main_channel_id = ChannelId("C0123")

import DandelionSlack: OutgoingEvent, OutgoingMessageEvent, send_event
import Niancat: prettify

type TestEvent
    channel::ChannelId
    has_texts::Vector{UTF8String}
    has_not_texts::Vector{UTF8String}
    TestEvent(channelId::ChannelId, xs...; has_not=[]) = new(channelId, [xs...], has_not)
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
        IncorrectSolutionResponse(ChannelId("D0"), Word("FOO"), :not_in_dictionary),
        [TestEvent(ChannelId("D0"), "FOO", "inte")]),

    ResponderTest(
        "Correct solution response to user",
        CorrectSolutionResponse(ChannelId("D0"), Word("FOO")),
        [TestEvent(ChannelId("D0"), "FOO", "korrekt")]),

    ResponderTest(
        "Unknown user",
        UnknownUserSolutionResponse(UserId("U0")),
        [TestEvent(main_channel_id, "<@U0>", "känd")]),

    ResponderTest(
        "Get puzzle, many solutions",
        GetPuzzleResponse(ChannelId("C0"), Puzzle("PUZZLEABC"), 17),
        [TestEvent(ChannelId("C0"), "PUZ ZLE ABC", "17")]),

    ResponderTest(
        "Get puzzle, one solution",
        GetPuzzleResponse(ChannelId("C0"), Puzzle("PUZZLEABC"), 1),
        [TestEvent(ChannelId("C0"), "PUZ ZLE ABC"; has_not=["1"])]),

    ResponderTest(
        "No puzzle set",
        NoPuzzleSetResponse(ChannelId("C0")),
        [TestEvent(ChannelId("C0"), "inte", "satt")]),

    ResponderTest(
        "Set puzzle response, many solutions",
        SetPuzzleResponse(ChannelId("C0"), Puzzle("PUZZLEABC"), 17),
        [TestEvent(ChannelId("C0"), "PUZ ZLE ABC", "17")]),

    ResponderTest(
        "Set puzzle response, one solution",
        SetPuzzleResponse(ChannelId("C0"), Puzzle("PUZZLEABC"), 1),
        [TestEvent(ChannelId("C0"), "PUZ ZLE ABC"; has_not=["1"])]),

    ResponderTest(
        "Invalid puzzle",
        InvalidPuzzleResponse(ChannelId("C0"), Puzzle("PUZZLE")),
        [TestEvent(ChannelId("C0"), "PUZZLE")]),

    ResponderTest(
        "Ignore events",
        IgnoredEventResponse(ChannelId("C0"), utf8("Some text")),
        []),

    ResponderTest(
        "Composite responses",
        CompositeResponse(
            CorrectSolutionResponse(ChannelId("D0"), Word("FOO")),
            SolutionNotificationResponse(SlackName("erike"), utf8("abcdef"))),
        [TestEvent(ChannelId("D0"), "FOO"),
         TestEvent(ChannelId("C0123"), "erike", "abcdef")]),

    ResponderTest(
        "Invalid command",
        InvalidCommandResponse(ChannelId("C0"), :unknown),
        [TestEvent(ChannelId("C0"), "känt")]),

    ResponderTest(
        "Help command",
        HelpResponse(ChannelId("C0")),
        [TestEvent(ChannelId("C0"), "!setnian", "!nian", "!helpnian")]),

    ResponderTest(
        "Incorrect solution, because it's not nine characters",
        IncorrectSolutionResponse(ChannelId("D0"), Word("FOO"), :not_nine_characters),
        [TestEvent(ChannelId("D0"), "FOO", "inte nio tecken")]),

    ResponderTest(
        "Incorrect solution, because it doesn't match todays puzzle",
        NonMatchingWordResponse(
            ChannelId("D0"), Word("FOO"), Puzzle("BAR"), utf8("ABC"), utf8("DEF")),
        [TestEvent(ChannelId("D0"), "FOO", "BAR", "matchar inte", "många ABC", "få DEF")]),

    ResponderTest(
        "Incorrect solution, because it doesn't match todays puzzle",
        NonMatchingWordResponse(
            ChannelId("D0"), Word("FOO"), Puzzle("BAR"), utf8("ABC"), utf8("")),
        [TestEvent(ChannelId("D0"), "FOO", "matchar inte", "många ABC";
            has_not=["få"])]),

    ResponderTest(
        "Incorrect solution, because it doesn't match todays puzzle",
        NonMatchingWordResponse(
            ChannelId("D0"), Word("FOO"), Puzzle("BAR"), utf8(""), utf8("DEF")),
        [TestEvent(ChannelId("D0"), "FOO", "matchar inte", "få DEF";
            has_not=["många"])]),

    ResponderTest(
        "Incorrect solution, for unknown reason",
        IncorrectSolutionResponse(ChannelId("D0"), Word("FOO"), :other_reason),
        [TestEvent(ChannelId("D0"), "FOO", "oklara skäl")]),

    ResponderTest(
        "Set an unsolution",
        SetUnsolutionResponse(ChannelId("D0"), utf8("Hello")),
        [TestEvent(ChannelId("D0"), "Hello", "Olösning")]),

    ResponderTest(
        "Get an unsolution",
        GetUnsolutionsResponse(ChannelId("D0"), [utf8("Hello"), utf8("world")]),
        [TestEvent(ChannelId("D0"), "Hello", "world")]),

    ResponderTest(
        "Notification response",
        UnsolutionNotificationResponse(Dict{UserId, UnsolutionList}(
            UserId("U0") => [utf8("FOO")],
            UserId("U1") => [utf8("BAR"), utf8("BAZ")])),
        [TestEvent(main_channel_id, "<@U0>", "FOO", "<@U1>", "BAR", "BAZ")]),

    ResponderTest(
        "Previous solutions response",
        PreviousSolutionsResponse(Dict{Word, Vector{UserId}}(
            Word("FOO") => [UserId("U0"), UserId("U1")],
            Word("BAR") => [])),
        [TestEvent(main_channel_id, "<@U0>", "FOO", "<@U1>", "BAR", "Gårdagens lösningar")]),

    ResponderTest(
        "Previous solutions response, only one solution",
        PreviousSolutionsResponse(Dict{Word, Vector{UserId}}(
            Word("FOO") => [UserId("U0"), UserId("U1")])),
        [TestEvent(main_channel_id, "<@U0>", "FOO", "<@U1>", "Gårdagens lösning";
            has_not=["lösningar"])])
]

facts("Responder") do
    context("Prettify solutions") do
        @fact prettify(Puzzle("PUZZLEABC")) --> Puzzle("PUZ ZLE ABC")
        @fact prettify(Puzzle("ÅABCDEFÄÖ")) --> Puzzle("ÅAB CDE FÄÖ")
    end

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

                for text in test_event.has_not_texts
                    @fact contains(message.text, text) --> false
                end
            end
        end
    end
end