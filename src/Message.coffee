class Message
    constructor: (bot, message, match) ->
        @bot = bot
        @message = message
        @match = match
        @response = ""
        
    reply: (message) ->
        @bot.reply @message, message
        
    send: (message) ->
        @bot.send @message, message
        
    emote: (message) ->
        @bot.emote @message, message
    
module.exports = Message