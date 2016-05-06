export parse_command

type CommandParser
    parameters::Int
    response_type::DataType
    parameter_function::Function

    CommandParser(parameters::Int, response_type::DataType, f::Function) =
        new(parameters, response_type, f)

    CommandParser(response_type::DataType) = new(0, response_type, x -> ())
end

commands = Dict{UTF8String, CommandParser}(
    "!setnian" => CommandParser(1, SetPuzzleCommand, x -> [Puzzle(x[1])]),
    "!nian" => CommandParser(GetPuzzleCommand),
    "!helpnian" => CommandParser(HelpCommand))

check_command = CommandParser(-1, CheckSolutionCommand, x -> [Word(join(x))])

is_private(channel::ChannelId) = !isempty(channel.v) && first(channel) == 'D'

function parse_command_parser(
    parser::CommandParser,
    parameters::Vector{SubString{UTF8String}},
    event::MessageEvent)

    if parser.parameters != -1 && length(parameters) != parser.parameters
        return InvalidCommand(event.channel, event.user, event.text, :wrong_no_of_parameters)
    end

    parser.response_type(event.channel, event.user, parser.parameter_function(parameters)...)
end

function parse_command(event::MessageEvent)
    parts = split(event.text)
    if isempty(parts)
        return IgnoredEventCommand(event.channel, event.user, event.text)
    end

    command = parts[1]

    if first(command) != '!'
        if is_private(event.channel)
            return parse_command_parser(check_command, parts, event)
        end
        return IgnoredEventCommand(event.channel, event.user, event.text)
    end

    if !haskey(commands, command)
        if is_private(event.channel)
            return InvalidCommand(event.channel, event.user, event.text, :unknown)
        end
        return IgnoredEventCommand(event.channel, event.user, event.text)
    end

    parser = commands[command]
    return parse_command_parser(parser, parts[2:end], event)
end

