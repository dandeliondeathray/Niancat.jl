immutable RemindersTest
    description::UTF8String
    initial_commands::Vector{AbstractCommand}
    command::Nullable{AbstractCommand}
    fun::Nullable{Function}
    response::AbstractResponse

    RemindersTest(;
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

reminders_tests = [
    RemindersTest(
        description = "Set a reminder",
        command     = SetReminderCommand(ChannelId("D0"), UserId("U0"), utf8("A reminder")),
        response    = SetReminderResponse(ChannelId("D0"), utf8("A reminder"))),

    RemindersTest(
        description      = "Get a reminder",
        initial_commands = [SetReminderCommand(ChannelId("D0"), UserId("U0"), utf8("A reminder"))],
        command          = GetRemindersCommand(ChannelId("D0"), UserId("U0")),
        response         = GetRemindersResponse(ChannelId("D0"), [utf8("A reminder")])),

    RemindersTest(
        description      = "Notify public channel about one reminder",
        initial_commands = [SetReminderCommand(ChannelId("D0"), UserId("U0"), utf8("A reminder"))],
        fun              = reminder_notification,
        response         = ReminderNotificationResponse(Dict{UserId, ReminderList}(
                               UserId("U0") => [utf8("A reminder")]))),

    RemindersTest(
        description      = "Get a reminder in public when no reminders were set",
        command          = GetRemindersCommand(ChannelId("C0"), UserId("U0")),
        response         = GetRemindersResponse(ChannelId("C0"), [])),

    RemindersTest(
        description      = "Get a reminder in public leads to private response",
        initial_commands = [SetReminderCommand(ChannelId("D0"), UserId("U0"), utf8("A reminder"))],
        command          = GetRemindersCommand(ChannelId("C0"), UserId("U0")),
        response         = GetRemindersResponse(ChannelId("D0"), [utf8("A reminder")])),
]

facts("Reminders") do
    for test in reminders_tests
        context(test.description) do
            reminders = Reminders()

            for initial_c in test.initial_commands
                reminder(reminders, initial_c)
            end

            if !isnull(test.command)
                @fact reminder(reminders, get(test.command)) --> test.response
            end

            if !isnull(test.fun)
                @fact get(test.fun)(reminders) --> test.response
            end
        end
    end

    context("Entries are cleared on notification") do
        reminders = Reminders()
        reminder(reminders, SetReminderCommand(ChannelId("D0"), UserId("U0"), utf8("A reminder")))

        @fact reminder_notification(reminders) --> ReminderNotificationResponse(
            Dict{UserId, ReminderList}(UserId("U0") => [utf8("A reminder")]))

        @fact reminder_notification(reminders) --> ReminderNotificationResponse(
            Dict{UserId, ReminderList}())
    end
end