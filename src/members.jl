export Members, add, remove, find_name, retrieve_user_list

import DandelionSlack: User, UserId, SlackChannel, ChannelId

immutable Members <: AbstractMembers
    users::Dict{UserId, User}
    channels::Dict{ChannelId, SlackChannel}
    web_api_call::Function

    Members(;web_api_call=x -> makerequest(x, requests)) =
        new(Dict{UserId, User}(), Dict{ChannelId, SlackChannel}(), web_api_call)
end

add(m::Members, user::User) = m.users[user.id] = user
add(m::Members, channel::SlackChannel) = m.channels[channel.id] = channel

remove(m::Members, userId::UserId) = delete!(m.users, userId)
remove(m::Members, channelId::ChannelId) = delete!(m.channels, channelId)

add(m::Members, xs...) = for x in xs add(m, x) end
remove(m::Members, xs...) = for x in xs remove(m, x) end

find_name(m::Members, userId::UserId) =
    haskey(m.users, userId) ?
        Nullable{SlackName}(m.users[userId].name) :
        Nullable{SlackName}()

find_name(m::Members, channelId::ChannelId) =
    haskey(m.channels, channelId) ?
        Nullable{SlackName}(m.channels[channelId].name) :
        Nullable{SlackName}()

function retrieve_user_list(m::Members, token::Token)
    status, user_list = m.web_api_call(UsersList(token, Nullable{Int}()))
    if status.ok
        add(m, user_list.members...)
    end
end