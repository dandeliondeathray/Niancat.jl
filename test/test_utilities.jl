import Niancat: find_name, retrieve_user_list, add, UnsolutionEntry
import DandelionSlack: User, AbstractRTMClient, OutgoingEvent, send_event, attach, close
import Base: ==

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


==(a::UnsolutionEntry, b::UnsolutionEntry) = a.channel == b.channel && a.texts == b.texts


type FakeRTMClient <: AbstractRTMClient
    messages::Vector{OutgoingEvent}
    handler::Nullable{RTMHandler}
    close_called::Int

    FakeRTMClient() = new([], Nullable{RTMHandler}(), 0)
end

send_event(c::FakeRTMClient, event::OutgoingEvent) = push!(c.messages, event)
attach(c::FakeRTMClient, handler::RTMHandler) = c.handler = Nullable{RTMHandler}(handler)
close(c::FakeRTMClient) = c.close_called += 1

function take_message!(c::FakeRTMClient)
    @fact c.messages --> not(isempty)
    ev = shift!(c.messages)
    @fact typeof(ev) --> OutgoingMessageEvent
    ev
end

is_handler_set(c::FakeRTMClient) = !isnull(c.handler)