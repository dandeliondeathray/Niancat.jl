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
        "Set reminder command",
        "!reminder FOO BAR BAZ qux", im_channel,
        SetReminderCommand(im_channel, test_user, "FOO BAR BAZ qux")),

    CommandParserTest(
        "Set reminder command with no params",
        "!reminder   ", im_channel,
        InvalidCommand(im_channel, test_user, "!reminder   ", :wrong_no_of_parameters)),

    CommandParserTest(
        "Set reminder command ignored in public channel",
        "!reminder FOO BAR BAZ qux", test_channel,
        IgnoredEventCommand(test_channel, test_user, "!reminder FOO BAR BAZ qux")),

    CommandParserTest(
        "Get reminders",
        "!reminders", im_channel,
        GetRemindersCommand(im_channel, test_user)),

    CommandParserTest(
        "Get reminders is also accepted in public (but response is in private)",
        "!reminders", test_channel,
        GetRemindersCommand(test_channel, test_user)),

    CommandParserTest(
        "Get reminders too many params",
        "!reminders COOL COOL COOL", im_channel,
        InvalidCommand(im_channel, test_user, "!reminders COOL COOL COOL",
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