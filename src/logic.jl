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
    solutions::UInt

    Logic(words::AbstractWordDictionary) = new(Nullable{Puzzle}(), words, 0)
    Logic(p::Nullable{Puzzle}, words::AbstractWordDictionary, s::Int) =
        new(Nullable{Puzzle}(p), words, s)
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
