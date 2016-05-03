import DandelionSlack: @newtype, @newimmutable, @stringinterface

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

immutable CompositeResponse <: AbstractResponse

end

