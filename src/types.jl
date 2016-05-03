import DandelionSlack: @newtype, @newimmutable, @stringinterface
import Base: start, done, endof, next

export Puzzle, Word, ChannelOrUser,
       AbstractCommand, AbstractResponse,
       CheckSolutionCommand, GetPuzzleCommand, SetPuzzleCommand,
       IncorrectSolutionResponse, CorrectSolutionResponse, SolutionNotificationResponse,
       GetPuzzleResponse, NoPuzzleSetResponse, SetPuzzleResponse, InvalidPuzzleResponse,
       CompositeResponse, UnknownUserSolutionResponse, IgnoredEventCommand, IgnoredEventResponse

#
# Helper types
#

@newimmutable Puzzle <: UTF8String
@stringinterface Puzzle

@newimmutable Word <: UTF8String
@stringinterface Word

ChannelOrUser = Union{UserId, ChannelId}

#
# Commands
#

abstract AbstractCommand

immutable CheckSolutionCommand <: AbstractCommand
    user::UserId
    word::Word
end

immutable GetPuzzleCommand <: AbstractCommand
    from::ChannelOrUser
end

immutable SetPuzzleCommand <: AbstractCommand
    from::ChannelOrUser
    puzzle::Puzzle
end

immutable IgnoredEventCommand <: AbstractCommand
    from::ChannelOrUser
    text::UTF8String
end

#
# Responses
#

abstract AbstractResponse

immutable IncorrectSolutionResponse <: AbstractResponse
    user::UserId
    word::Word
end

immutable CorrectSolutionResponse <: AbstractResponse
    user::UserId
    word::Word
end

immutable SolutionNotificationResponse <: AbstractResponse
    user::UserId
    hash::UTF8String
end

immutable UnknownUserSolutionResponse <: AbstractResponse
    user::UserId
end

immutable GetPuzzleResponse <: AbstractResponse
    from::ChannelOrUser
    puzzle::Puzzle
    solutions::UInt
end

immutable NoPuzzleSetResponse <: AbstractResponse
    from::ChannelOrUser
end

immutable SetPuzzleResponse <: AbstractResponse
    from::ChannelOrUser
    puzzle::Puzzle
    solutions::UInt
end

immutable InvalidPuzzleResponse <: AbstractResponse
    from::ChannelOrUser
    puzzle::Puzzle
end

immutable IgnoredEventResponse <: AbstractResponse
    from::ChannelOrUser
    text::UTF8String
end

immutable CompositeResponse <: AbstractResponse
    responses::Vector{AbstractResponse}

    CompositeResponse(v...) = new([v...])
end

endof(c::CompositeResponse) = endof(c.responses)
next(c::CompositeResponse, i::Int) = next(c.responses, i)
start(c::CompositeResponse) = start(c.responses)
done(c::CompositeResponse, i::Int) = done(c.responses, i)