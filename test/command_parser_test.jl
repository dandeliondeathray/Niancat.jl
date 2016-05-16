test_user = UserId("U0")
test_channel = ChannelId("C0")
im_channel = ChannelId("D0")

type CommandParserTest
    description::AbstractString
    text::UTF8String
    channel::ChannelId
    expected::AbstractCommand
end

function ==(a::AbstractCommand, b::AbstractCommand)
    if typeof(a) != typeof(b)
        return false
    end

    for field_name in fieldnames(a)
        if getfield(a, field_name) != getfield(b, field_name)
            return false
        end
    end

    true
end

command_parser_tests = [
    CommandParserTest(
        "Set puzzle",
        "!setnian ABCDEFGHI", test_channel,
        SetPuzzleCommand(test_channel, test_user, Puzzle("ABCDEFGHI"))),

    CommandParserTest(
        "Get puzzle",
        "!nian", test_channel,
        GetPuzzleCommand(test_channel, test_user)),

    CommandParserTest(
        "Help",
        "!helpnian", test_channel,
        HelpCommand(test_channel, test_user)),

    CommandParserTest(
        "Ignore non-commands in public channel",
        "ABCDEFGHI", test_channel,
        IgnoredEventCommand(test_channel, test_user, "ABCDEFGHI")),

    CommandParserTest(
        "Check solution",
        "ABCDEFGHI", im_channel,
        CheckSolutionCommand(im_channel, test_user, Word("ABCDEFGHI"))),

    CommandParserTest(
        "Check solution, with spaces",
        "ABC DEF GHI", im_channel,
        CheckSolutionCommand(im_channel, test_user, Word("ABCDEFGHI"))),

    CommandParserTest(
        "No command",
        "  ", test_channel,
        IgnoredEventCommand(test_channel, test_user, "  ")),

    CommandParserTest(
        "Unknown command in public channel",
        "!nosuchcommand", test_channel,
        IgnoredEventCommand(test_channel, test_user, "!nosuchcommand")),

    CommandParserTest(
        "Unknown command in private channel",
        "!nosuchcommand", im_channel,
        InvalidCommand(im_channel, test_user, "!nosuchcommand", :unknown)),

    CommandParserTest(
        "Set puzzle with too many parameters",
        "!setnian ABCDEFGHI more parameters", test_channel,
        InvalidCommand(test_channel, test_user,
                       "!setnian ABCDEFGHI more parameters", :wrong_no_of_parameters)),

    CommandParserTest(
        "Get puzzle with too many parameters",
        "!nian yoyoyo", test_channel,
        InvalidCommand(test_channel, test_user, "!nian yoyoyo", :wrong_no_of_parameters)),

    CommandParserTest(
        "Help with too many parameters",
        "!helpnian yoyoyo", test_channel,
        InvalidCommand(test_channel, test_user, "!helpnian yoyoyo", :wrong_no_of_parameters)),

    CommandParserTest(
        "Set unsolution command",
        "!unsolution FOO BAR BAZ qux", im_channel,
        SetUnsolutionCommand(im_channel, test_user, "FOO BAR BAZ qux")),

    CommandParserTest(
        "Set unsolution command with no params",
        "!unsolution   ", im_channel,
        InvalidCommand(im_channel, test_user, "!unsolution   ", :wrong_no_of_parameters)),

    CommandParserTest(
        "Set unsolution command ignored in public channel",
        "!unsolution FOO BAR BAZ qux", test_channel,
        IgnoredEventCommand(test_channel, test_user, "!unsolution FOO BAR BAZ qux")),

    CommandParserTest(
        "Get unsolutions",
        "!unsolutions", im_channel,
        GetUnsolutionsCommand(im_channel, test_user)),

    CommandParserTest(
        "Get unsolutions is also accepted in public (but response is in private)",
        "!unsolutions", test_channel,
        GetUnsolutionsCommand(test_channel, test_user)),

    CommandParserTest(
        "Get unsolutions, too many params",
        "!unsolutions COOL COOL COOL", im_channel,
        InvalidCommand(im_channel, test_user, "!unsolutions COOL COOL COOL",
                       :wrong_no_of_parameters)),
]

facts("CommandParser") do
    for test in command_parser_tests
        context(test.description) do
            event = MessageEvent(test.text, test.channel, test_user, EventTimestamp("123"))
            actual = parse_command(event)
            @fact actual --> test.expected
        end
    end
end