# Niancat.jl

## Core features
- Keep todays puzzle
- Commands
    + !nian
    + !setnian
    + !help
- Handle solutions attempts in private channels with users
- Notify main channel on solution
- Solution notification includes user name and SHA256 hash of solution and user

## Other features
- Store latest puzzle on filesystem, and recover it on startup
- User can store unsolutions as reminders, automatically posted when the next puzzle is set.
- The bot will verify that the puzzle has a solution, to help with typos
- The bot will notify the channel if there is more than one solution