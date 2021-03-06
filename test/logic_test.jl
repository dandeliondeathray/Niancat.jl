import Base.==

import Niancat: is_solution, no_of_solutions, handle, non_match, unsolution, unsolution_notification,
                UnsolutionList, find_solutions

#
# Test data
#

hash_tests = [
    ("GALLTJUTA", "f00ale",   "f72e9a9523bbc72bf7366a58a04046408d2d88ea811afdc9a459d24e077fa71d"),
    ("GALLTJUTA", "erike",    "d8e7363cdad6303dd4c41cb2ad3e2c35759257ca8ac509107e4e9e9ff5741933"),
    ("GALLTJUTA", "cadaker",  "203ecbdeba638d0c6c4a3a3ab17c2704bdf9c79016a392ccf303615534392e9c"),
    ("GALLTJUTA", "johaper",  "80b3ac9c8150684994df7302a3897fbfe551c52dcd2c8cb2e1cf948129ce9483"),
    ("GALLTJUTA", "andrnils", "2da8b95f6d58652bf87547ed0106e3d2a8e2915cc9b09710ef52d57aa43df5c8"),

    ("ÅÄÖABCDEF", "f00ale",   "71edbbe7b1905edc4daf94208ce22eb570fc478de0b346743abd7449d1e7d822"),
    ("ÅÄÖABCDEF", "erike",    "adbc40e1e9d2c5da069c410a9d6e6d485fd2f7e14856b97560e759ad028b9d2d"),
    ("ÅÄÖABCDEF", "cadaker",  "0d7d353ab20469b1c4bf8446d7297860022bbc19c6ae771f351ae597bf56e0dd"),
    ("ÅÄÖABCDEF", "johaper",  "9280130c1ee9109b63810d5cfdcb456fba8fd5d742b578f60e947c24ba5a6c4f"),
    ("ÅÄÖABCDEF", "andrnils", "8027afb1b362daa27be64edf1806d50a344082d3a534cfc38c827a7e71bc8779")
]

non_matching_tests = [
    (Puzzle("GALLTJUTA"), Word("GALLTJUTR"), utf8("R"), utf8("A")),
    (Puzzle("GALLTJUTA"), Word("GALRTJUTA"), utf8("R"), utf8("L")),
    (Puzzle("GALLTJUTA"), Word("GBLLTJUTC"), utf8("BC"), utf8("AA")),
    (Puzzle("ABCDEFÅÄÖ"), Word("ABCDEFÅÄÄ"), utf8("Ä"), utf8("Ö"))
]

user_id0    = UserId("U0")
user_id1    = UserId("U1")
channel_id0 = ChannelId("C0")
channel_id1 = ChannelId("C1")
puzzle0     = Puzzle("ABCDEFGHI")
puzzle1     = Puzzle("GHIJKLMNO")

#
# Equality
#

function ==(a::AbstractResponse, b::AbstractResponse)
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

#
# Mocks
#

fake_members = FakeMemberScroll()

immutable FakeWordDictionary <: AbstractWordDictionary
    is_solution_::Bool
    no_of_solutions_::Int
    solutions::Vector{Word}

    FakeWordDictionary(i::Bool, n::Int; solutions::Vector{Word}=Vector{Word}()) = new(i, n, solutions)
end

is_solution(f::FakeWordDictionary, w::Word) = f.is_solution_
no_of_solutions(f::FakeWordDictionary, w::Puzzle) = f.no_of_solutions_
find_solutions(f::FakeWordDictionary, p::Puzzle) = f.solutions

type FakeUnsolutions <: AbstractUnsolutions
    response::Nullable{AbstractResponse}

    FakeUnsolutions() = new(Nullable{AbstractResponse}())
    FakeUnsolutions(c::AbstractResponse) = new(Nullable{AbstractResponse}(c))
end

unsolution(r::FakeUnsolutions, ::AbstractCommand) = get(r.response)
unsolution_notification(r::FakeUnsolutions) = get(r.response)

type FakeUnsolutionCommand <: AbstractUnsolutionCommand end
type FakeUnsolutionResponse <: AbstractResponse end

#
# Tests
#

facts("Niancat logic") do
    context("Test response equality") do
        @fact GetPuzzleResponse(channel_id0, puzzle0, 1) -->
            GetPuzzleResponse(channel_id0, puzzle0, 1)
        @fact GetPuzzleResponse(channel_id0, puzzle0, 1) -->
            not(GetPuzzleResponse(channel_id0, puzzle1, 1))
        @fact GetPuzzleResponse(channel_id0, puzzle0, 1) -->
            not(GetPuzzleResponse(channel_id1, puzzle0, 1))
    end

    context("Solution hash") do
        for (word, nick, expected) in hash_tests
            @fact Niancat.solution_hash(utf8(word), utf8(nick)) --> expected
        end
    end

    context("Non-matching help") do
        for (puzzle, word, too_many, too_few) in non_matching_tests
            @fact non_match(puzzle, word) --> (too_many, too_few)
        end
    end

    context("Get puzzle") do
        words = FakeWordDictionary(true, 1)
        command = GetPuzzleCommand(channel_id0, user_id0)
        logic = Logic(Nullable{Puzzle}(puzzle0), words, fake_members, Unsolutions(), 1)
        @fact handle(logic, command) --> GetPuzzleResponse(channel_id0, puzzle0, 1)
    end

    context("Get puzzle when not set") do
        words = FakeWordDictionary(true, 1)
        command = GetPuzzleCommand(channel_id0, user_id0)
        logic = Logic(words, fake_members)
        @fact handle(logic, command) --> NoPuzzleSetResponse(channel_id0)
    end

    context("Set puzzle") do
        words = FakeWordDictionary(true, 1)
        logic = Logic(words, fake_members)
        get_command = GetPuzzleCommand(channel_id0, user_id0)
        set_command = SetPuzzleCommand(channel_id0, user_id0, Puzzle("ABCDEFGHI"))

        expected = SetPuzzleResponse(channel_id0, puzzle0, 1)

        @fact handle(logic, set_command) --> expected
        @fact handle(logic, get_command) --> GetPuzzleResponse(channel_id0, puzzle0, 1)
    end

    context("Set invalid puzzle") do
        words = FakeWordDictionary(true, 0)
        logic = Logic(Nullable{Puzzle}(puzzle1), words, fake_members, Unsolutions(), 1)
        get_command = GetPuzzleCommand(channel_id0, user_id0)
        set_command = SetPuzzleCommand(channel_id0, user_id0, puzzle0)
        @fact handle(logic, set_command) --> InvalidPuzzleResponse(channel_id0, puzzle0)
        @fact handle(logic, get_command) --> GetPuzzleResponse(channel_id0, puzzle1, 1)
    end

    context("Set puzzle, multiple solutions") do
        solutions = 17
        words = FakeWordDictionary(true, solutions)
        logic = Logic(words, fake_members)
        get_command = GetPuzzleCommand(channel_id0, user_id0)
        set_command = SetPuzzleCommand(channel_id0, user_id0, Puzzle("ABCDEFGHI"))

        @fact handle(logic, set_command) --> SetPuzzleResponse(channel_id0, puzzle0, solutions)
        @fact handle(logic, get_command) --> GetPuzzleResponse(channel_id0, puzzle0, solutions)
    end

    context("Solve the puzzle") do
        name = utf8("erike")
        member_scroll = FakeMemberScroll(user_id0, name)
        words = FakeWordDictionary(true, 1)
        word = Word("GALL-TJU TA")
        logic = Logic(words, member_scroll)
        logic.puzzle = Nullable{Puzzle}(Puzzle("AGALLTJUT"))
        expected_hash = utf8("d8e7363cdad6303dd4c41cb2ad3e2c35759257ca8ac509107e4e9e9ff5741933")
        command = CheckSolutionCommand(channel_id0, user_id0, word)

        response = handle(logic, command)
        @fact isa(response, CompositeResponse) --> true

        solution_response, notification_response = response

        @fact solution_response --> CorrectSolutionResponse(channel_id0, normalize(word))
        @fact notification_response --> SolutionNotificationResponse(SlackName(name), expected_hash)
    end

    context("Incorrect solution, because it's not in the dictionary") do
        member_scroll = FakeMemberScroll()
        words = FakeWordDictionary(false, 1)
        logic = Logic(words, member_scroll)
        logic.puzzle = Nullable{Puzzle}(Puzzle("AGALLTJUT"))
        word = Word("GALLTJUTA")
        command = CheckSolutionCommand(channel_id0, user_id0, word)
        @fact handle(logic, command) -->
            IncorrectSolutionResponse(channel_id0, word, :not_in_dictionary)
    end

    context("Incorrect solution, because it's not not nine characters") do
        member_scroll = FakeMemberScroll()
        words = FakeWordDictionary(false, 1)
        logic = Logic(words, member_scroll)
        logic.puzzle = Nullable{Puzzle}(Puzzle("GALLTJUTA"))
        word = Word("GALLA")
        command = CheckSolutionCommand(channel_id0, user_id0, word)
        @fact handle(logic, command) -->
            IncorrectSolutionResponse(channel_id0, word, :not_nine_characters)
    end

    context("Incorrect solution, because it doesn't match the puzzle") do
        member_scroll = FakeMemberScroll()
        words = FakeWordDictionary(false, 1)
        logic = Logic(words, member_scroll)
        puzzle = Puzzle("ABCDEFGHI")
        logic.puzzle = Nullable{Puzzle}(puzzle)
        word = Word("GALLTJUTA")
        command = CheckSolutionCommand(channel_id0, user_id0, word)
        @fact handle(logic, command) -->
            NonMatchingWordResponse(channel_id0, word, puzzle,
                utf8("AJLLTTU"), utf8("BCDEFHI"))
    end

    context("Incorrect solution, because the puzzle isn't set") do
        member_scroll = FakeMemberScroll()
        words = FakeWordDictionary(false, 1)
        logic = Logic(words, member_scroll)
        word = Word("GALLTJUTA")
        command = CheckSolutionCommand(channel_id0, user_id0, word)
        @fact handle(logic, command) --> NoPuzzleSetResponse(channel_id0)
    end

    context("Unknown user") do
        member_scroll = FakeMemberScroll()
        words = FakeWordDictionary(true, 1)
        logic = Logic(words, member_scroll)
        logic.puzzle = Nullable{Puzzle}(Puzzle("AGALLTJUT"))
        word = Word("GALLTJUTA")
        command = CheckSolutionCommand(channel_id0, user_id0, word)
        response = handle(logic, command)
        @fact isa(response, CompositeResponse) --> true
        correct_response, unknown_response = response
        @fact correct_response --> CorrectSolutionResponse(channel_id0, word)
        @fact unknown_response --> UnknownUserSolutionResponse(user_id0)
    end

    context("Ignored event") do
        member_scroll = FakeMemberScroll()
        words = FakeWordDictionary(true, 1)
        logic = Logic(words, member_scroll)
        text = utf8("some text")
        command = IgnoredEventCommand(channel_id0, user_id0, text)
        @fact handle(logic, command) --> IgnoredEventResponse(channel_id0, text)
    end

    context("Invalid command") do
        member_scroll = FakeMemberScroll()
        words = FakeWordDictionary(true, 1)
        logic = Logic(words, member_scroll)
        command = InvalidCommand(channel_id0, user_id0, "", :unknown)
        @fact handle(logic, command) --> InvalidCommandResponse(channel_id0, :unknown)
    end

    context("Help command") do
        member_scroll = FakeMemberScroll()
        words = FakeWordDictionary(true, 1)
        logic = Logic(words, member_scroll)
        command = HelpCommand(channel_id0, user_id0)
        @fact handle(logic, command) --> HelpResponse(channel_id0)
    end

    context("Unsolution command is propagated to unsolutions type") do
        words = FakeWordDictionary(true, 1)
        logic = Logic(Nullable{Puzzle}(puzzle0), words, fake_members,
            FakeUnsolutions(FakeUnsolutionResponse()), 0)
        @fact handle(logic, FakeUnsolutionCommand()) --> FakeUnsolutionResponse()
    end

    context("Unsolution notification is done on next set, with no previous puzzle") do
        words = FakeWordDictionary(true, 1)

        notification_response = UnsolutionNotificationResponse(Dict{UserId, UnsolutionList}(
            UserId("U0") => [utf8("Hello")]))

        # No previous puzzle means that Logic will not respond with any previous solutions.
        logic = Logic(Nullable{Puzzle}(), words, fake_members,
                      FakeUnsolutions(notification_response), 1)
        set_command = SetPuzzleCommand(channel_id0, user_id0, Puzzle("ABCDEFGHI"))

        expected = CompositeResponse(
            SetPuzzleResponse(channel_id0, puzzle0, 1),
            notification_response)

        @fact handle(logic, set_command) --> expected
    end

   context("Unsolution notification is done on next set, with previous solutions") do
        words = FakeWordDictionary(true, 2; solutions=[Word("FOO"), Word("BAR")])

        notification_response = UnsolutionNotificationResponse(Dict{UserId, UnsolutionList}(
            UserId("U0") => [utf8("Hello")]))

        logic = Logic(Nullable{Puzzle}(Puzzle("QUX")), words, fake_members,
                      FakeUnsolutions(notification_response), 2)
        logic.solved[Word("FOO")] = [UserId("U0"), UserId("U1")]

        expected_solutions = PreviousSolutionsResponse(Dict{Word, Vector{UserId}}(
            Word("FOO") => [UserId("U0"), UserId("U1")],
            Word("BAR") => Vector{UserId}()))

        set_command = SetPuzzleCommand(channel_id0, user_id0, Puzzle("ABCDEFGHI"))

        expected = CompositeResponse(
            SetPuzzleResponse(channel_id0, puzzle0, 2),
            notification_response,
            expected_solutions)

        @fact handle(logic, set_command) --> expected
    end


    context("Unsolution notification is not done on invalid set") do
        words = FakeWordDictionary(true, 0)

        # An empty FakeUnsolutions causes it to throw an exception when called.
        # Therefore, if unsolution_notification is called, then this test will fail.
        logic = Logic(Nullable{Puzzle}(), words, fake_members, FakeUnsolutions(), 0)
        set_command = SetPuzzleCommand(channel_id0, user_id0, Puzzle("ABCDEFGHI"))

        handle(logic, set_command)
    end

    context("Store solutions and user that solved it") do
        words = FakeWordDictionary(true, 2; solutions=[Word("IABCDEFGH"), Word("ABCDEFGHI")])

        logic = Logic(Nullable{Puzzle}(Puzzle("DEFGHIABC")), words, fake_members,
                      FakeUnsolutions(), 2)

        handle(logic, CheckSolutionCommand(ChannelId("D0"), UserId("U0"), Word("ABCDEFGHI")))
        handle(logic, CheckSolutionCommand(ChannelId("D1"), UserId("U1"), Word("ABCDEFGHI")))

        @fact logic.solved[Word("ABCDEFGHI")] --> [UserId("U0"), UserId("U1")]
        @fact haskey(logic.solved, Word("IABCDEFGH")) --> false
    end

    context("Clear solutions on next set") do
        words = FakeWordDictionary(true, 2; solutions=[Word("IABCDEFGH"), Word("ABCDEFGHI")])


        notification_response = UnsolutionNotificationResponse(Dict{UserId, UnsolutionList}(
            UserId("U0") => [utf8("Hello")]))
        logic = Logic(Nullable{Puzzle}(Puzzle("DEFGHIABC")), words, fake_members,
                      FakeUnsolutions(notification_response), 2)

        handle(logic, CheckSolutionCommand(ChannelId("D0"), UserId("U0"), Word("ABCDEFGHI")))
        handle(logic, CheckSolutionCommand(ChannelId("D1"), UserId("U1"), Word("ABCDEFGHI")))

        set_command = SetPuzzleCommand(channel_id0, user_id0, Puzzle("ABCDEFGHI"))
        set_response = handle(logic, set_command)
        @fact isa(set_response, InvalidPuzzleResponse) --> false

        @fact logic.solved --> isempty
    end
end