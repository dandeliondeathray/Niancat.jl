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

A `CheckSolutionCommand` has the following properties:

- A word
- A user id


Logic
-----
The logic of the bot is handled here. The `Logic` type has a single function
`handle(::AbstractLogic, ::AbstractCommand)`, which returns one of several response objects:

- `CorrectSolutionResponse`
- `IncorrectSolutionResponse`
- `SolutionNotificationResponse`
- `TodaysPuzzleResponse`
- `SetTodaysPuzzleResponse`
- `HelpResponse`
- `InvalidCommandResponse`
- `CompositeResponse`

All of these responses inherit from `AbstractResponse`.

This design only allows for direct responses to commands. It does not allow for asynchronous
responses, or the logic to do anything outside of respond directly. This is good enough, at least
for the time being.

The `CompositeResponse` type is necessary for cases when the bot should response to one or more
channels. For instance, when responding to a correct solution the bot should send one message on a
private channel to the user who found the solution, and one message to the general channel
notifying others that the solution has been found. These are two separate response types,
`CorrectSolutionResponse` and `SolutionNotificationResponse`, so they are combined into a single
response type `CompositeResponse`.

Response types
--------------

`SolutionNotificationResponse` has the fields:

- Solution hash
- User id

`CorrectSolutionResponse` has the fields:

- User id
- Word

`CompositeResponse` implements the iteration interface.

Responder
---------
The `Responder` type is responsible for sending a response via Slack. It creates Slack messages,
each based on the type of response.

The responder owns the `RTMClient` object, which it uses to send messages. Additionally, it is
provided with the channel id for the general channel where it should post notifications.

For the `SolutionNotificationResponse` type it creates a Slack message with the solution hash in the
text (along with a message saying that a solution was found by the user). For this it must map from
the user id provided by the logic type, to a user name, as we don't want a user to get a
notification that it was mentioned in the main channel.

Problem: If the bot sends the user id as "<@U0123> found a solution! XXXX", then that user will get
a notification that it was mentioned. A user won't want that notification, since it is expected.
Therefore we must send the name of the user rather than the id. We must therefore have a mapping
from user id to user name. We'll create a separate type for that, just as with the word dictionary.

Word dictionary
---------------
The word dictionary keeps a list of all valid words for the puzzle. It has two function

`is_solution(::AbstractWordDictionary, word::UTF8String)`

:    Returns true if a given word is a solution, false otherwise.

`no_of_solutions(::AbstractWordDictionary, puzzle::UTF8String)`

:    Finds the number of solutions for a given puzzle.

Member scroll
-------------
This keeps track of user, and allows the responder to map from user id to name.