abstract AbstractMemberScroll

find_name(t::AbstractMemberScroll, ::UserId) =
    error("find_name not implemented for $(t) and UserId")
find_name(t::AbstractMemberScroll, ::ChannelId) =
    error("find_name not implemented for $(t) and ChannelId")

abstract AbstractWordDictionary

is_solution(d::AbstractWordDictionary, w::Word) =
    error("is_solution not implemented for $(d) and $(w)")
no_of_solutions(d::AbstractWordDictionary, p::Puzzle) =
    error("no_of_solutions not implemented for $(d) and $(p)")

abstract AbstractLogic

handle(l::AbstractLogic, c::AbstractCommand) = error("handle not implemented for $(l) and $(c)")
