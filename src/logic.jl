export Logic,
       handle

import Nettle

function solution_hash(word::UTF8String, nick::UTF8String)
    Nettle.hexdigest("sha256", word * nick)
end

matches(puzzle::Puzzle, word::Word) = sort_and_normalize(puzzle.v) == sort_and_normalize(word.v)

function string_to_dict{T}(s::T)
    d = Dict{Char, Int}()
    for c in s
        d[c] = get(d, c, 0) + 1
    end
    d
end

# Given a puzzle, and a word that doesn't match that puzzle, find what characters there are too many
# of and what characters there are too few of.
function non_match(p::Puzzle, w::Word)
    puzzle_dict = string_to_dict(p.v)
    word_dict = string_to_dict(w.v)

    too_many = ""
    too_few = ""

    for w in Set{Char}([collect(w); collect(p)])
        wn = get(word_dict, w, 0)
        pn = get(puzzle_dict, w, 0)

        if wn < pn
            too_few = too_few * utf8(repeat("$w", pn - wn))
        elseif wn > pn
            too_many = too_many * utf8(repeat("$w", wn - pn))
        end
    end
    return (utf8(sort(collect(too_many))), utf8(sort(collect(too_few))))
end

abstract AbstractLogic

type Logic <: AbstractLogic
    puzzle::Nullable{Puzzle}
    words::AbstractWordDictionary
    members::AbstractMembers
    unsolutions::AbstractUnsolutions
    solutions::UInt
    solved::Dict{Word, Vector{UserId}}

    Logic(words::AbstractWordDictionary, m::AbstractMembers) =
        new(Nullable{Puzzle}(), words, m, Unsolutions(), 0, Dict{Word, Vector{UserId}}())
    Logic(p::Nullable{Puzzle},
          words::AbstractWordDictionary,
          m::AbstractMembers,
          r::AbstractUnsolutions,
          s::Int) = new(Nullable{Puzzle}(p), words, m, r, s, Dict{Word, Vector{UserId}}())
end

function handle(logic::Logic, command::GetPuzzleCommand)
    if isnull(logic.puzzle)
        return NoPuzzleSetResponse(command.channel)
    end

    GetPuzzleResponse(command.channel, get(logic.puzzle), logic.solutions)
end

function handle(logic::Logic, command::SetPuzzleCommand)
    new_no_of_solutions = no_of_solutions(logic.words, command.puzzle)

    if new_no_of_solutions == 0
        return InvalidPuzzleResponse(command.channel, command.puzzle)
    end
    logic.solutions = new_no_of_solutions


    set_puzzle_response = SetPuzzleResponse(command.channel, command.puzzle, logic.solutions)
    responses = Vector{AbstractResponse}([set_puzzle_response])

    notification_response = unsolution_notification(logic.unsolutions)
    if !isempty(notification_response.entries)
        push!(responses, notification_response)
    end

    if !isnull(logic.puzzle)
        all_solutions = find_solutions(logic.words, get(logic.puzzle))
        solvers = Dict{Word, Vector{UserId}}([
            (w, get(logic.solved, w, Vector{UserId}()))
            for w in all_solutions
        ])
        push!(responses, PreviousSolutionsResponse(solvers))
    end

    logic.puzzle = command.puzzle
    empty!(logic.solved)

    if length(responses) == 1
        return responses[1]
    else
        return CompositeResponse(responses...)
    end
end

function handle(logic::Logic, command::CheckSolutionCommand)
    if isnull(logic.puzzle)
        return NoPuzzleSetResponse(command.channel)
    end

    if length(normalize(command.word)) != 9
        return IncorrectSolutionResponse(command.channel, command.word, :not_nine_characters)
    end

    if !matches(get(logic.puzzle), command.word)
        (too_many, too_few) = non_match(get(logic.puzzle), command.word)
        return NonMatchingWordResponse(command.channel, command.word, get(logic.puzzle),
            too_many, too_few)
    end

    if is_solution(logic.words, command.word)
        # Store solution locally so we can show every user that solved it.
        normalized_word = normalize(command.word)
        solvers = get(logic.solved, normalized_word, Vector{UserId}())
        push!(solvers, command.user)
        logic.solved[normalized_word] = solvers

        maybe_name = find_name(logic.members, command.user)
        if isnull(maybe_name)
            return CompositeResponse(
                CorrectSolutionResponse(command.channel, command.word),
                UnknownUserSolutionResponse(command.user))
        end
        # Note that `name` is a SlackName, not a UTF8String.
        name = get(maybe_name)
        hash = solution_hash(utf8(normalized_word), name.v)
        return CompositeResponse(
            CorrectSolutionResponse(command.channel, normalized_word),
            SolutionNotificationResponse(name, hash))
    else
        return IncorrectSolutionResponse(command.channel, command.word, :not_in_dictionary)
    end
end

handle(logic::Logic, c::AbstractUnsolutionCommand) = unsolution(logic.unsolutions, c)

handle(::Logic, command::IgnoredEventCommand) = IgnoredEventResponse(command.channel, command.text)
handle(::Logic, command::InvalidCommand) = InvalidCommandResponse(command.channel, command.reason)
handle(::Logic, command::HelpCommand) = HelpResponse(command.channel)
