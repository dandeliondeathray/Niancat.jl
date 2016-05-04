words = WordDictionary(Set{UTF8String}([
    "GALLTJUTA",
    "DATORSPEL",
    "SPELDATOR",
    "abcdefghi",
    "ABCDEFåäö"
    ]))

solution_tests = [
    "GALLTJUTA", "DATORSPEL", "SPELDATOR", "ABCDEFGHI", "ABCDEFÅÄÖ",
    "galltjuta", "datorspel", "speldator", "abcdefghi", "abcdefåäö",
    "gall tjuta", "  galltjuta  ", "gall-tjuta", "-galltjuta -----     "
]

non_solution_tests = [
    "GALLTJUT", "GALLTJUTAA", "åäöabcdef"
]

normalize_tests = [
    ("GALLTJUTA", "GALLTJUTA"),
    ("galltjuta", "GALLTJUTA"),
    ("DATORSPEL", "DATORSPEL"),
    ("datorspel", "DATORSPEL"),
    ("dator spel", "DATORSPEL"),
    ("dator-spel", "DATORSPEL"),
    ("  dator-spel\n", "DATORSPEL"),
    ("abcdefåöl", "ABCDEFÅÄÖ")
]

no_of_solutions_tests = [
    ("GALLTJUTA", 1),
    ("TJUTAGALL", 1),
    ("DATORSPEL", 2),
    ("SPELDATOR", 2),
    ("SPDATOREL", 2),
    ("ÅÄÖABCDEF", 1),
    ("AAAAAAAAA", 0)
]

facts("Word dictionary") do
    context("Is solution") do
        for word in solution_tests
            @fact is_solution(words, Word(word)) --> true
        end

        for word in non_solution_tests
            @fact is_solution(words, Word(word)) --> false
        end
    end

    context("Normalization") do
        for (word, expected) in normalize_tests
            @fact normalize(words, word) --> expected
        end
    end

    context("Number of solutions") do
        for (puzzle, n) in no_of_solutions_tests
            @fact no_of_solutions(words, Puzzle(puzzle)) --> n
        end
    end
end