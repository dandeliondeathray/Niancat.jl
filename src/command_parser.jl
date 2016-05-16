export parse_command

type CommandParser
    parameters::Int
    response_type::DataType
    parameter_function::Function
    is_private::Bool

    CommandParser(parameters::Int, response_type::DataType, f::Function; is_private::Bool=false) =
        new(parameters, response_type, f, is_private)

    CommandParser(response_type::DataType) = new(0, response_type, (x, _) -> ())
end

commands = Dict{UTF8String, CommandParser}(
    "!setnian" => CommandParser(1, SetPuzzleCommand, (x, _) -> [Puzzle(x[1])]),
    "!nian" => CommandParser(GetPuzzleCommand),
    "!helpnian" => CommandParser(HelpCommand),
    "!unsolution" => CommandParser(-2, SetUnsolutionCommand, (_, y) -> [y], is_private=true),
    "!unsolutions" => CommandParser(GetUnsolutionsCommand))

check_command = CommandParser(-1, CheckSolutionCommand, (x, _) -> [Word(join(x))])

is_private(channel::ChannelId) = !isempty(channel.v) && first(channel) == 'D'

function parse_command_parser(
    parser::CommandParser,
    parameters::Vector{SubString{UTF8String}},
    parameters_string::UTF8String,
    event::MessageEvent)

    if parser.parameters >= 0 && length(parameters) != parser.parameters
        return InvalidCommand(event.channel, event.user, event.text, :wrong_no_of_parameters)
    elseif parser.parameters == -2 && parameters_string == ""
        return InvalidCommand(event.channel, event.user, event.text, :wrong_no_of_parameters)
    end

    if parser.is_private && !is_private(event.channel)
        return IgnoredEventCommand(event.channel, event.user, event.text)
    end

    parser.response_type(event.channel, event.user,
        parser.parameter_function(parameters, parameters_string)...)
end

function parse_command(event::MessageEvent)
    parts = split(event.text)
    if isempty(parts)
        return IgnoredEventCommand(event.channel, event.user, event.text)
    end

    command = parts[1]

    # Some commands want all of the following text as one parameter, including whitespace.
    parameters_string = utf8("")
    if length(parts) >= 2
        parameters_string = utf8(split(event.text, [' ','\t','\n','\v','\f','\r']; limit=2)[2])
    end

    if first(command) != '!'
        if is_private(event.channel)
            return parse_command_parser(check_command, parts, utf8(""), event)
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
    return parse_command_parser(parser, parts[2:end], parameters_string, event)
end

