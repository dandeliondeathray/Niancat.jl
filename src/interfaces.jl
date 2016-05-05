export AbstractMembers, AbstractWordDictionary, AbstractLogic,
       find_name, is_solution, no_of_solutions, handle

abstract AbstractMembers

find_name(t::AbstractMembers, ::UserId) =
    error("find_name not implemented for $(t) and UserId")
find_name(t::AbstractMembers, ::ChannelId) =
    error("find_name not implemented for $(t) and ChannelId")

abstract AbstractWordDictionary

# Check is a word is in the dictionary.
is_solution(d::AbstractWordDictionary, w::Word) =
    error("is_solution not implemented for $(d) and $(w)")
no_of_solutions(d::AbstractWordDictionary, p::Puzzle) =
    error("no_of_solutions not implemented for $(d) and $(p)")

abstract AbstractLogic

handle(l::AbstractLogic, c::AbstractCommand) = error("handle not implemented for $(l) and $(c)")
