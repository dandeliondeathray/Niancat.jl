import Base.==

import Niancat: find_name, is_solution, no_of_solutions, handle

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

user_id0    = UserId("U0")
user_id1    = UserId("U1")
channel_id0 = ChannelId("C0")
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

immutable FakeMemberScroll <: AbstractMemberScroll
    user::Nullable{UTF8String}
    channel::Nullable{UTF8String}

    FakeMemberScroll() = new(Nullable(), Nullable())
    FakeMemberScroll(u::UTF8String) = new(Nullable(u), Nullable())
end

find_name(s::FakeMemberScroll, ::UserId) = s.user
find_name(s::FakeMemberScroll, ::ChannelId) = s.channel

fake_members = FakeMemberScroll()

immutable FakeWordDictionary <: AbstractWordDictionary
    is_solution_::Bool
    no_of_solutions_::Int
end

is_solution(f::FakeWordDictionary, w::Word) = f.is_solution_
no_of_solutions(f::FakeWordDictionary, w::Puzzle) = f.no_of_solutions_

#
# Tests
#

facts("Niancat logic") do
    context("Test response equality") do
        @fact GetPuzzleResponse(user_id0, puzzle0, 1) --> GetPuzzleResponse(user_id0, puzzle0, 1)
        @fact GetPuzzleResponse(user_id0, puzzle0, 1) -->
            not(GetPuzzleResponse(user_id0, puzzle1, 1))
        @fact GetPuzzleResponse(user_id0, puzzle0, 1) -->
            not(GetPuzzleResponse(user_id1, puzzle0, 1))
    end

    context("Solution hash") do
        for (word, nick, expected) in hash_tests
            @fact Niancat.solution_hash(utf8(word), utf8(nick)) --> expected
        end
    end

    context("Get puzzle") do
        words = FakeWordDictionary(true, 1)
        command = GetPuzzleCommand(user_id0)
        logic = Logic(Nullable{Puzzle}(puzzle0), words, fake_members, 1)
        @fact handle(logic, command) --> GetPuzzleResponse(user_id0, puzzle0, 1)
    end

    context("Get puzzle when not set") do
        words = FakeWordDictionary(true, 1)
        command = GetPuzzleCommand(user_id0)
        logic = Logic(words, fake_members)
        @fact handle(logic, command) --> NoPuzzleSetResponse(user_id0)
    end

    context("Set puzzle") do
        words = FakeWordDictionary(true, 1)
        logic = Logic(words, fake_members)
        get_command = GetPuzzleCommand(user_id0)
        set_command = SetPuzzleCommand(user_id0, Puzzle("ABCDEFGHI"))

        expected = SetPuzzleResponse(user_id0, puzzle0, 1)

        @fact handle(logic, set_command) --> expected
        @fact handle(logic, get_command) --> GetPuzzleResponse(user_id0, puzzle0, 1)
    end

    context("Set invalid puzzle") do
        words = FakeWordDictionary(true, 0)
        logic = Logic(Nullable{Puzzle}(puzzle1), words, fake_members, 1)
        get_command = GetPuzzleCommand(user_id0)
        set_command = SetPuzzleCommand(user_id0, puzzle0)
        @fact handle(logic, set_command) --> InvalidPuzzleResponse(user_id0, puzzle0)
        @fact handle(logic, get_command) --> NoPuzzleSetResponse(user_id0)
    end

    context("Set puzzle, multiple solutions") do
        solutions = 17
        words = FakeWordDictionary(true, solutions)
        logic = Logic(words, fake_members)
        get_command = GetPuzzleCommand(user_id0)
        set_command = SetPuzzleCommand(user_id0, Puzzle("ABCDEFGHI"))

        @fact handle(logic, set_command) --> SetPuzzleResponse(user_id0, puzzle0, solutions)
        @fact handle(logic, get_command) --> GetPuzzleResponse(user_id0, puzzle0, solutions)
    end

    context("Solve the puzzle") do
        name = utf8("erike")
        member_scroll = FakeMemberScroll(name)
        words = FakeWordDictionary(true, 1)
        word = Word("GALLTJUTA")
        logic = Logic(words, member_scroll)
        expected_hash = utf8("d8e7363cdad6303dd4c41cb2ad3e2c35759257ca8ac509107e4e9e9ff5741933")
        command = CheckSolutionCommand(user_id0, word)

        response = handle(logic, command)
        @fact isa(response, CompositeResponse) --> true

        solution_response, notification_response = response

        @fact solution_response --> CorrectSolutionResponse(user_id0, word)
        @fact notification_response --> SolutionNotificationResponse(user_id0, expected_hash)
    end

    context("Incorrect solution") do
        @pending false --> true
    end

    context("Unknown user") do
        @pending false --> true
    end
end