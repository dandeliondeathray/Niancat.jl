export parse_dictionary

function parse_dictionary(s::IO)
    lines = readlines(s)
    words = map(x -> strip(utf8(x)), lines)
    filter!(w -> length(w) == 9, words)
    WordDictionary(Set{UTF8String}(words))
end