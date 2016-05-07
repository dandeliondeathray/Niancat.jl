import Niancat: find_name, retrieve_user_list, add
import DandelionSlack: User

type FakeMemberScroll <: AbstractMembers
    users::Dict{UserId, SlackName}
    channels::Dict{ChannelId, SlackName}
    retrieve_calls::UInt

    FakeMemberScroll() = new(Dict(), Dict(), 0)
    FakeMemberScroll(id::UserId, u::UTF8String) = new(Dict(id => SlackName(u)), Dict(), 0)
end

function find_name(s::FakeMemberScroll, id::UserId)
    if haskey(s.users, id)
        Nullable(s.users[id])
    else
        Nullable()
    end
end

find_name(s::FakeMemberScroll, id::ChannelId) = Nullable(s.channels[id])
retrieve_user_list(s::FakeMemberScroll, token::Token) = s.retrieve_calls += 1

add(s::FakeMemberScroll, u::User) = s.users[u.id] = u.name
add(s::FakeMemberScroll, us...) = for u in us add(s, u) end