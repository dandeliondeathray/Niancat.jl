export Logic,
       handle

import Nettle

function solution_hash(word::UTF8String, nick::UTF8String)
    Nettle.hexdigest("sha256", word * nick)
end

abstract AbstractLogic

type Logic
    puzzle::Nullable{Puzzle}
end

function handle(logic::Logic, command::GetPuzzleCommand)
    if isnull(logic.puzzle)
        NoPuzzleSetResponse(command.from)
    else
        GetPuzzleResponse(command.from, get(logic.puzzle))
    end
end