#!/usr/bin/env julia

using DocOpt
using DandelionSlack
using DandelionSlack.Util
using Niancat
import Requests

doc = """Niancat: assist in solving word puzzles.

Usage:
    niancat.jl <team> <channel> <dictionary>

Examples:
    niancat.jl myslackteam general
"""

args = docopt(doc, version=v"0.1.0")

function find_channel(token::Token, channel_name::UTF8String)
    channels_list = ChannelsList(token, Nullable{Int64}())
    try
        status, response = makerequest(channels_list, requests)
        channel_index = findfirst(c -> c.name == channel_name, response.channels)
        if channel_index == 0
            println("No channel named $(channel_name) in team $(team)")
            return Nullable{SlackChannel}()
        else
            channel = response.channels[channel_index]
            return Nullable{SlackChannel}(channel)
        end
    catch ex
        println("$ex")
        return Nullable{SlackChannel}()
    end
end

token = find_token(args["<team>"])
channel_name = args["<channel>"]
dictionary_file = args["<dictionary>"]
channel = find_channel(token, channel_name)

if isnull(channel)
    exit(1)
end

channel_id = get(channel).id

status, response = makerequest(RtmStart(token, Nullable(), Nullable(), Nullable()), requests)
if !status.ok
    println("Could not start RTM: $(status.error)")
    exit(1)
end

words = parse_dictionary(open(dictionary_file))

members = Members()
handler = NiancatHandler(members, words, channel_id, token)
client = rtm_connect(Requests.URI(response.url), handler)
on_create(handler, client)

while true
    sleep(10)
end