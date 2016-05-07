import Niancat: find_name, retrieve_user_list

immutable FakeMemberScroll <: AbstractMembers
    user::Nullable{SlackName}
    channel::Nullable{SlackName}

    FakeMemberScroll() = new(Nullable(), Nullable())
    FakeMemberScroll(u::UTF8String) = new(Nullable(SlackName(u)), Nullable())
end

find_name(s::FakeMemberScroll, ::UserId) = s.user
find_name(s::FakeMemberScroll, ::ChannelId) = s.channel
retrieve_user_list(s::FakeMemberScroll, token::Token) = nothing
