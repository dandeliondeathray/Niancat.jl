export Logic,
       handle

import Nettle

function solution_hash(word::UTF8String, nick::UTF8String)
    Nettle.hexdigest("sha256", word * nick)
end

abstract AbstractLogic

type Logic
    puzzle::Nullable{Puzzle}
    words::AbstractWordDictionary
    members::AbstractMembers
    solutions::UInt

    Logic(words::AbstractWordDictionary, m::AbstractMembers) =
        new(Nullable{Puzzle}(), words, m, 0)
    Logic(p::Nullable{Puzzle}, words::AbstractWordDictionary, m::AbstractMembers, s::Int) =
        new(Nullable{Puzzle}(p), words, m, s)
end

function handle(logic::Logic, command::GetPuzzleCommand)
    if isnull(logic.puzzle)
        return NoPuzzleSetResponse(command.from)
    end

    GetPuzzleResponse(command.from, get(logic.puzzle), logic.solutions)
end

function handle(logic::Logic, command::SetPuzzleCommand)
    logic.solutions = no_of_solutions(logic.words, command.puzzle)

    if logic.solutions == 0
        logic.puzzle = Nullable{Puzzle}()
        return InvalidPuzzleResponse(command.from, command.puzzle)
    end

    logic.puzzle = command.puzzle
    SetPuzzleResponse(command.from, command.puzzle, logic.solutions)
end

function handle(logic::Logic, command::CheckSolutionCommand)
    if is_solution(logic.words, command.word)
        maybe_name = find_name(logic.members, command.user)
        if isnull(maybe_name)
            return CompositeResponse(
                CorrectSolutionResponse(command.user, command.word),
                UnknownUserSolutionResponse(command.user))
        end
        # Note that `name` is a SlackName, not a UTF8String.
        name = get(maybe_name)
        normalized_word = normalize(command.word)
        hash = solution_hash(utf8(normalized_word), name.v)
        return CompositeResponse(
            CorrectSolutionResponse(command.user, normalized_word),
            SolutionNotificationResponse(command.user, hash))
    else
        return IncorrectSolutionResponse(command.user, command.word)
    end
end

handle(::Logic, command::IgnoredEventCommand) = IgnoredEventResponse(command.from, command.text)