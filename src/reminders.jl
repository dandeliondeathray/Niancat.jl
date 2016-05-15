export Reminders, reminder, reminder_notification

type Reminders <: AbstractReminders
    entries::Dict{UserId, ReminderEntry}

    Reminders() = new(Dict{UserId, ReminderEntry}())
end

function reminder(r::Reminders, command::SetReminderCommand)
    # This defaults to a newly constructed entry with the specified channel as the response channel.
    # This means that if the user, hypothetically, was to set a reminder from two different
    # channels, then the bot will respond in the first of those channels, since that's the one where
    # this default construction of ReminderEntry is done.
    entry = get(r.entries, command.user, ReminderEntry(command.channel))
    push!(entry.texts, command.text)
    r.entries[command.user] = entry
    SetReminderResponse(command.channel, command.text)
end

function reminder(r::Reminders, command::GetRemindersCommand)
    texts = []
    if haskey(r.entries, command.user)
        # When there are reminders, list them in the private channel specified in the entry.
        entry = r.entries[command.user]
        return GetRemindersResponse(entry.channel, entry.texts)
    end

    # When there are no reminders, list them in then channel the command came from, even if that is
    # a public channel. Since there are no reminders, there's nothing to spoil.
    GetRemindersResponse(command.channel, texts)
end


function reminder_notification(r::Reminders)
    response = ReminderNotificationResponse(copy(r.entries))
    empty!(r.entries)
    response
end