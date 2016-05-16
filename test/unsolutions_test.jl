immutable UnsolutionsTest
    description::UTF8String
    initial_commands::Vector{AbstractCommand}
    command::Nullable{AbstractCommand}
    fun::Nullable{Function}
    response::AbstractResponse

    UnsolutionsTest(;
        description=utf8(""),
        initial_commands=Vector{AbstractCommand}(),
        command=nothing,
        fun=nothing,
        response=nothing) =

        new(description, initial_commands,
            command == nothing ? Nullable{AbstractCommand}() : Nullable{AbstractCommand}(command),
            fun == nothing ? Nullable{Function}() : Nullable{Function}(fun),
            response)
end

unsolutions_tests = [
    UnsolutionsTest(
        description = "Set a unsolution",
        command     = SetUnsolutionCommand(ChannelId("D0"), UserId("U0"), utf8("An unsolution")),
        response    = SetUnsolutionResponse(ChannelId("D0"), utf8("An unsolution"))),

    UnsolutionsTest(
        description      = "Get a unsolution",
        initial_commands = [SetUnsolutionCommand(ChannelId("D0"),
                                                 UserId("U0"),
                                                 utf8("An unsolution"))],
        command          = GetUnsolutionsCommand(ChannelId("D0"), UserId("U0")),
        response         = GetUnsolutionsResponse(ChannelId("D0"), [utf8("An unsolution")])),

    UnsolutionsTest(
        description      = "Notify public channel about one unsolution",
        initial_commands = [SetUnsolutionCommand(ChannelId("D0"),
                                                 UserId("U0"),
                                                 utf8("An unsolution"))],
        fun              = unsolution_notification,
        response         = UnsolutionNotificationResponse(Dict{UserId, UnsolutionList}(
                               UserId("U0") => [utf8("An unsolution")]))),

    UnsolutionsTest(
        description      = "Get a unsolution in public when no unsolutions were set",
        command          = GetUnsolutionsCommand(ChannelId("C0"), UserId("U0")),
        response         = GetUnsolutionsResponse(ChannelId("C0"), [])),

    UnsolutionsTest(
        description      = "Get a unsolution in public leads to private response",
        initial_commands = [SetUnsolutionCommand(ChannelId("D0"),
                                                 UserId("U0"),
                                                 utf8("An unsolution"))],
        command          = GetUnsolutionsCommand(ChannelId("C0"), UserId("U0")),
        response         = GetUnsolutionsResponse(ChannelId("D0"), [utf8("An unsolution")])),
]

facts("Unsolutions") do
    for test in unsolutions_tests
        context(test.description) do
            unsolutions = Unsolutions()

            for initial_c in test.initial_commands
                unsolution(unsolutions, initial_c)
            end

            if !isnull(test.command)
                @fact unsolution(unsolutions, get(test.command)) --> test.response
            end

            if !isnull(test.fun)
                @fact get(test.fun)(unsolutions) --> test.response
            end
        end
    end

    context("Entries are cleared on notification") do
        unsolutions = Unsolutions()
        unsolution(unsolutions, SetUnsolutionCommand(
            ChannelId("D0"), UserId("U0"), utf8("An unsolution")))

        @fact unsolution_notification(unsolutions) --> UnsolutionNotificationResponse(
            Dict{UserId, UnsolutionList}(UserId("U0") => [utf8("An unsolution")]))

        @fact unsolution_notification(unsolutions) --> UnsolutionNotificationResponse(
            Dict{UserId, UnsolutionList}())
    end
end