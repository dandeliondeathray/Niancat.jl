import DandelionSlack: @newtype, @newimmutable, @stringinterface
import Base: start, done, endof, next

export Puzzle, Word,
       AbstractCommand, AbstractResponse,
       CheckSolutionCommand, GetPuzzleCommand, SetPuzzleCommand, HelpCommand, InvalidCommand,
       IncorrectSolutionResponse, CorrectSolutionResponse, SolutionNotificationResponse,
       GetPuzzleResponse, NoPuzzleSetResponse, SetPuzzleResponse, InvalidPuzzleResponse,
       CompositeResponse, UnknownUserSolutionResponse, IgnoredEventCommand, IgnoredEventResponse,
       InvalidCommandResponse, HelpResponse, NonMatchingWordResponse,
       SetUnsolutionCommand, GetUnsolutionsCommand, SetUnsolutionResponse, GetUnsolutionsResponse,
       UnsolutionNotificationResponse, UnsolutionList, AbstractUnsolutionCommand,
       PreviousSolutionsResponse

#
# Helper types
#

@newimmutable Puzzle <: UTF8String
@stringinterface Puzzle

@newimmutable Word <: UTF8String
@stringinterface Word

typealias UnsolutionList Vector{UTF8String}

type UnsolutionEntry
    channel::ChannelId
    texts::UnsolutionList

    UnsolutionEntry(channel::ChannelId) = new(channel, [])
    UnsolutionEntry(channel::ChannelId, texts::UnsolutionList) = new(channel, texts)
end

#
# Commands
#

abstract AbstractCommand

immutable CheckSolutionCommand <: AbstractCommand
    channel::ChannelId
    user::UserId
    word::Word
end

immutable GetPuzzleCommand <: AbstractCommand
    channel::ChannelId
    user::UserId
end

immutable SetPuzzleCommand <: AbstractCommand
    channel::ChannelId
    user::UserId
    puzzle::Puzzle
end

immutable IgnoredEventCommand <: AbstractCommand
    channel::ChannelId
    user::UserId
    text::UTF8String
end

immutable HelpCommand <: AbstractCommand
    channel::ChannelId
    user::UserId
end

immutable InvalidCommand <: AbstractCommand
    channel::ChannelId
    user::UserId
    text::UTF8String
    reason::Symbol
end

abstract AbstractUnsolutionCommand <: AbstractCommand
immutable SetUnsolutionCommand <: AbstractUnsolutionCommand
    channel::ChannelId
    user::UserId
    text::UTF8String
end

immutable GetUnsolutionsCommand <: AbstractUnsolutionCommand
    channel::ChannelId
    user::UserId
end

#
# Responses
#

abstract AbstractResponse

immutable IncorrectSolutionResponse <: AbstractResponse
    channel::ChannelId
    word::Word
    reason::Symbol
end

immutable CorrectSolutionResponse <: AbstractResponse
    channel::ChannelId
    word::Word
end

immutable SolutionNotificationResponse <: AbstractResponse
    name::SlackName
    hash::UTF8String
end

immutable UnknownUserSolutionResponse <: AbstractResponse
    user::UserId
end

immutable GetPuzzleResponse <: AbstractResponse
    channel::ChannelId
    puzzle::Puzzle
    solutions::UInt
end

immutable NoPuzzleSetResponse <: AbstractResponse
    channel::ChannelId
end

immutable SetPuzzleResponse <: AbstractResponse
    channel::ChannelId
    puzzle::Puzzle
    solutions::UInt
end

immutable InvalidPuzzleResponse <: AbstractResponse
    channel::ChannelId
    puzzle::Puzzle
end

immutable IgnoredEventResponse <: AbstractResponse
    channel::ChannelId
    text::UTF8String
end

immutable InvalidCommandResponse <: AbstractResponse
    channel::ChannelId
    reason::Symbol
end

immutable HelpResponse <: AbstractResponse
    channel::ChannelId
end

immutable NonMatchingWordResponse <: AbstractResponse
    channel::ChannelId
    word::Word
    puzzle::Puzzle
    too_many::UTF8String
    too_few::UTF8String
end

immutable SetUnsolutionResponse <: AbstractResponse
    channel::ChannelId
    text::UTF8String
end

immutable GetUnsolutionsResponse <: AbstractResponse
    channel::ChannelId
    texts::UnsolutionList
end

immutable UnsolutionNotificationResponse <: AbstractResponse
    entries::Dict{UserId, UnsolutionList}
end

immutable PreviousSolutionsResponse <: AbstractResponse
    solvers::Dict{Word, Vector{UserId}}
end

immutable CompositeResponse <: AbstractResponse
    responses::Vector{AbstractResponse}

    CompositeResponse(v...) = new([v...])
end

endof(c::CompositeResponse) = endof(c.responses)
next(c::CompositeResponse, i::Int) = next(c.responses, i)
start(c::CompositeResponse) = start(c.responses)
done(c::CompositeResponse, i::Int) = done(c.responses, i)