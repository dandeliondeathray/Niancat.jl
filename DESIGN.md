Design of Niancat.jl
====================
Niancat.jl based on the Slack API package DandelionSlack.jl. The main part of Niancat.jl is
the type `NiancatHandler`, which is the type that handles incoming Slack events.

There are three phases when dealing with an incoming Slack message:

1. Parse the message into a command, possibly an invalid command: `CommandParser`
2. Let the logic type handle the command, and get a response back: `Logic`
3. Forward the response to the user: `Responder`

These steps are handled synchronously. All of these types have abstract counterparts, to enable
testing of each unit separately.

CommandParser
-------------
The `CommandParser` type has a single method `parse(::AbstractCommandParser, text::UTF8String)`,
which returns one of the command types:

- `SetPuzzleCommand`
- `GetPuzzleCommand`
- `CheckSolutionCommand`
- `ShowHelpCommand`
- `InvalidCommand`

All these types inherit from the abstract type `AbstractCommand`.

Logic
-----
The logic of the bot is handled here. The `Logic` type has a single function
`handle(::AbstractLogic, ::AbstractCommand)`, which returns one of several response objects:

