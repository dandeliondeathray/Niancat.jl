export WordDictionary,
       is_solution,
       no_of_solutions,
       find_solutions,
       normalize

sort_and_normalize(p::UTF8String) = utf8(sort([normalize(Word(p)).v...]))

type WordDictionary <: AbstractWordDictionary
    words::Set{Word}
    solutions::Dict{UTF8String, Vector{Word}}

    function WordDictionary(s::Set{UTF8String})
        words = Set{Word}(map(x -> normalize(Word(x)), s))
        solutions = Dict{UTF8String, Vector{Word}}()
        for w in words
            p = sort_and_normalize(w.v)
            w_solutions = get(solutions, p, Vector{Word}())
            push!(w_solutions, w)
            solutions[p] = w_solutions
        end
        new(words, solutions)
    end
end

# Check if a word is in the dictionary.
is_solution(d::WordDictionary, w::Word) = normalize(w) in d.words

# Check how many solutions a given puzzle has in the dictionary.
no_of_solutions(d::WordDictionary, p::Puzzle) =
  length(get(d.solutions, sort_and_normalize(p.v), Vector{Word}()))

find_solutions(d::WordDictionary, p::Puzzle) = get(d.solutions, sort_and_normalize(p.v), [])

# Normalize a word by removing all non-alpha characters.
normalize(w::Word) = Word(uppercase(replace(w, r"[^A-Za-zåäöÅÄÖ]", "")))