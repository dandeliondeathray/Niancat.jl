word_list = utf8("""
ABC
ABCDEF
ABCDEFGHI
ABCDEFÅÄÖ
ÅÄÖDEFGHI
speldator

datorspel
""")

expected = [utf8("ABCDEFGHI"), utf8("ABCDEFÅÄÖ"), utf8("ÅÄÖDEFGHI"), utf8("DATORSPEL"),
            utf8("SPELDATOR")]

unexpected = [utf8("ABC"), utf8("ABCDEF")]

facts("Bot initialization") do
    context("Filter puzzles") do
        s = IOBuffer(word_list)
        words = parse_dictionary(s)

        for w in expected
            @fact is_solution(words, Word(w)) --> true
        end

        for w in unexpected
            @fact is_solution(words, Word(w)) --> false
        end
    end
end