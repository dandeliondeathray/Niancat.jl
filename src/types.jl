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
    word::Word
    user::UserId
end

immutable GetPuzzleCommand <: AbstractCommand
    from::ChannelOrUser
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
end

immutable NoPuzzleSetResponse <: AbstractResponse
    from::ChannelOrUser
end

immutable CompositeResponse <: AbstractResponse

end

