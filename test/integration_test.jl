facts("Integration") do
    context("Set, get and solve the puzzle") do
        members = FakeMemberScroll()
        rtm_client = FakeRTMClient()
        words = WordDictionary(Set{UTF8String}([utf8("DEFABCGHI")]))
        token = Token("sometoken")

        handler = NiancatHandler(members, words, ChannelId("C0"), token)

        # Calling on_create lets the handler get a reference to RTMClient
        on_create(handler, rtm_client)

        # Add fake users to the member list
        add(members, u("U0", "User 0"), u("U1", "User 1"), u("U2", "User 2"))

        # A HelloEvent is the first event received when connected.
        # This must lead to a call to retrieve_user_list(::Members).
        @fact members.retrieve_calls --> 0
        on_event(handler, HelloEvent())
        @fact members.retrieve_calls --> 1

        # Set the puzzle
        on_event(handler,
            MessageEvent("!setnian ABCDEFGHI", ChannelId("C0"), UserId("U0"), EventTimestamp("123")))

        msg = take_message!(rtm_client)
        @fact contains(msg.text, utf8("Dagens nia är satt")) --> true
        @fact contains(msg.text, utf8("ABC DEF GHI")) --> true

        # Get the puzzle
        on_event(handler,
            MessageEvent("!nian", ChannelId("C0"), UserId("U0"), EventTimestamp("124")))
        msg = take_message!(rtm_client)
        @fact contains(msg.text, utf8("ABC DEF GHI")) --> true

        # Ignore solutions on a public channel
        on_event(handler,
            MessageEvent("DEF ABC GHI", ChannelId("C0"), UserId("U0"), EventTimestamp("125")))
        @fact rtm_client.messages --> isempty

        # Solve the puzzle on a private channel
        on_event(handler,
            MessageEvent("DEF ABC GHI", ChannelId("D0"), UserId("U0"), EventTimestamp("126")))
        # First we expect a private message with the right word, ...
        msg = take_message!(rtm_client)
        @fact msg.channel --> ChannelId("D0")
        @fact contains(msg.text, utf8("DEFABCGHI")) --> true

        # then we expect a solution notification to the main channe
        msg = take_message!(rtm_client)
        @fact contains(msg.text, utf8("User 0")) --> true
        @fact contains(msg.text, utf8("löste nian")) --> true
        @fact msg.channel --> ChannelId("C0")
    end

    context("Invalid commands") do
        members = FakeMemberScroll()
        rtm_client = FakeRTMClient()
        words = WordDictionary(Set{UTF8String}([utf8("DEFABCGHI")]))
        token = Token("sometoken")

        handler = NiancatHandler(members, words, ChannelId("C0"), token)

        on_create(handler, rtm_client)

        # Add fake users to the member list
        add(members, u("U0", "User 0"), u("U1", "User 1"), u("U2", "User 2"))

        on_event(handler, HelloEvent())

        # Invalid setting of puzzle
        on_event(handler,
            MessageEvent("!setnian TOO MANY ARGUMENTS",
                         ChannelId("C0"), UserId("U0"), EventTimestamp("123")))

        msg = take_message!(rtm_client)
        @fact msg.channel --> ChannelId("C0")
    end

    context("Error callbacks") do
        members = FakeMemberScroll()
        rtm_client = FakeRTMClient()
        words = WordDictionary(Set{UTF8String}([utf8("DEFABCGHI")]))
        token = Token("sometoken")

        handler = NiancatHandler(members, words, ChannelId("C0"), token)

        on_create(handler, rtm_client)
        add(members, u("U0", "User 0"), u("U1", "User 1"), u("U2", "User 2"))
        on_event(handler, HelloEvent())

        # Set the puzzle
        on_error(handler, DeserializationError(utf8("text"), "{}", MessageEvent))
    end

    context("Reminder notifications") do
        members = FakeMemberScroll()
        rtm_client = FakeRTMClient()
        words = WordDictionary(Set{UTF8String}([utf8("DEFABCGHI"), utf8("DEFABCJKL")]))
        token = Token("sometoken")

        handler = NiancatHandler(members, words, ChannelId("C0"), token)

        # Calling on_create lets the handler get a reference to RTMClient
        on_create(handler, rtm_client)

        # Add fake users to the member list
        add(members, u("U0", "User 0"), u("U1", "User 1"), u("U2", "User 2"))

        on_event(handler, HelloEvent())

        # Set the puzzle
        on_event(handler,
            MessageEvent("!setnian ABCDEFGHI", ChannelId("C0"), UserId("U0"), EventTimestamp("123")))

        msg = take_message!(rtm_client)
        @fact contains(msg.text, utf8("Dagens nia är satt")) --> true
        @fact contains(msg.text, utf8("ABC DEF GHI")) --> true

        # Set three reminder for two users, and expect response:
        # U0 => FOO
        # U1 => BAR, baz
        on_event(handler,
            MessageEvent("!reminder FOO", ChannelId("D0"), UserId("U0"), EventTimestamp("123")))

        msg = take_message!(rtm_client)
        @fact msg.channel --> ChannelId("D0")
        @fact contains(msg.text, utf8("FOO")) --> true

        on_event(handler,
            MessageEvent("!reminder BAR", ChannelId("D1"), UserId("U1"), EventTimestamp("123")))

        msg = take_message!(rtm_client)
        @fact msg.channel --> ChannelId("D1")
        @fact contains(msg.text, utf8("BAR")) --> true

        on_event(handler,
            MessageEvent("!reminder baz", ChannelId("D1"), UserId("U1"), EventTimestamp("123")))

        msg = take_message!(rtm_client)
        @fact msg.channel --> ChannelId("D1")
        @fact contains(msg.text, utf8("baz")) --> true

        # Get reminders for user U1, and set command on main channel, and receive command in
        # the private channel D1.
        on_event(handler,
            MessageEvent("!reminders", ChannelId("C0"), UserId("U1"), EventTimestamp("123")))

        msg = take_message!(rtm_client)
        @fact msg.channel --> ChannelId("D1")
        @fact contains(msg.text, utf8("BAR")) --> true
        @fact contains(msg.text, utf8("baz")) --> true


        # Set a new puzzle. This should lead to a notification response.
        # Set the puzzle
        on_event(handler,
            MessageEvent("!setnian ABCDEFJKL", ChannelId("C0"), UserId("U0"), EventTimestamp("123")))

        # We get a set response first.
        msg = take_message!(rtm_client)
        @fact contains(msg.text, utf8("Dagens nia är satt")) --> true
        @fact contains(msg.text, utf8("ABC DEF JKL")) --> true

        # Then we get a notification response.
        msg = take_message!(rtm_client)
        @fact contains(msg.text, utf8("U0")) --> true
        @fact contains(msg.text, utf8("U1")) --> true
        @fact contains(msg.text, utf8("FOO")) --> true
        @fact contains(msg.text, utf8("BAR")) --> true
        @fact contains(msg.text, utf8("baz")) --> true
    end
end

