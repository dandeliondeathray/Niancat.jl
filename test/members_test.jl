import DandelionSlack: User, SlackChannel, UserId, ChannelId
import Base: ==

profile = DandelionSlack.Profile(Nullable(), Nullable(), SlackName("Real name"), Nullable(),
                                 Nullable())

# A helper function to create a Slack User object.
u(userId::AbstractString, name::AbstractString) =
    User(UserId(utf8(userId)), SlackName(utf8(name)), false, "", profile, false, false, false,
         false, false, Nullable(), Nullable(), Nullable())

c(channelId::AbstractString, name::AbstractString) =
    SlackChannel(ChannelId(utf8(channelId)), SlackName(utf8(name)), true, 1, "", false, false,
                 Nullable(), Nullable(), Nullable(), false, Nullable(), Nullable(), Nullable())

=={T}(a::Nullable{T}, b::Nullable{T}) = isnull(a) && isnull(b) ||
    !isnull(a) && !isnull(b) && get(a) == get(b)

facts("Members") do
    context("UserId/ChannelId in dictionaries") do
        users = Dict{UserId, Int}(UserId("U0") => 0, UserId("U1") => 1)
        @fact haskey(users, UserId("U0")) --> true
        @fact haskey(users, UserId("U1")) --> true
        @fact haskey(users, UserId("U2")) --> false
        @fact users[UserId("U0")] --> 0
        @fact users[UserId("U1")] --> 1

        channels = Dict{ChannelId, Int}(ChannelId("C0") => 0, ChannelId("C1") => 1)
        @fact haskey(channels, ChannelId("C0")) --> true
        @fact haskey(channels, ChannelId("C1")) --> true
        @fact haskey(channels, ChannelId("C2")) --> false
        @fact channels[ChannelId("C0")] --> 0
        @fact channels[ChannelId("C1")] --> 1
    end

    context("No users or channels at creation") do
        members = Members()

        @fact find_name(members, UserId("U0")) --> isnull
        @fact find_name(members, ChannelId("C0")) --> isnull
    end

    context("Add a user") do
        members = Members()

        add(members, u("U0", "User 0"))
        @fact find_name(members, UserId("U0")) --> Nullable{SlackName}(SlackName("User 0"))
    end

    context("Add a channel") do
        members = Members()

        add(members, c("C0", "Channel 0"))
        @fact find_name(members, ChannelId("C0")) --> Nullable{SlackName}(SlackName("Channel 0"))
    end

    context("Multiple add") do
        members = Members()

        add(members, c("C0", "Channel 0"), c("C1", "Channel 1"))
        @fact find_name(members, ChannelId("C0")) --> Nullable{SlackName}(SlackName("Channel 0"))
        @fact find_name(members, ChannelId("C1")) --> Nullable{SlackName}(SlackName("Channel 1"))

        add(members, u("U0", "User 0"), u("U1", "User 1"))
        @fact find_name(members, UserId("U0")) --> Nullable{SlackName}(SlackName("User 0"))
        @fact find_name(members, UserId("U1")) --> Nullable{SlackName}(SlackName("User 1"))
    end

    context("Remove entries") do
        members = Members()

        # Users
        add(members, u("U0", "User 0"), u("U1", "User 1"), u("U2", "User 2"))
        remove(members, UserId("U0"))

        @fact find_name(members, UserId("U0")) --> isnull
        @fact find_name(members, UserId("U1")) --> Nullable{SlackName}(SlackName("User 1"))
        @fact find_name(members, UserId("U2")) --> Nullable{SlackName}(SlackName("User 2"))

        remove(members, UserId("U1"), UserId("U2"))
        @fact find_name(members, UserId("U0")) --> isnull
        @fact find_name(members, UserId("U1")) --> isnull
        @fact find_name(members, UserId("U2")) --> isnull

        # Channels
        add(members, c("C0", "Channel 0"), c("C1", "Channel 1"), c("C2", "Channel 2"))
        remove(members, ChannelId("C0"))
        @fact find_name(members, ChannelId("C0")) --> isnull
        @fact find_name(members, ChannelId("C1")) --> Nullable{SlackName}(SlackName("Channel 1"))
        @fact find_name(members, ChannelId("C2")) --> Nullable{SlackName}(SlackName("Channel 2"))

        remove(members, ChannelId("C1"), ChannelId("C2"))
        @fact find_name(members, ChannelId("C1")) --> isnull
        @fact find_name(members, ChannelId("C2")) --> isnull
    end

    context("Remove non-existent entry") do
        members = Members()

        remove(members, UserId("U0"))
        remove(members, ChannelId("C0"))
    end

    context("Add an existing user overwrites old") do
        members = Members()

        add(members, u("U0", "User 0"))
        add(members, u("U0", "User 0 again"))
        @fact find_name(members, UserId("U0")) --> Nullable{SlackName}(SlackName("User 0 again"))
    end
end


