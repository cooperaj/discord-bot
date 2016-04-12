class Message
    constructor: (bot, message, match) ->
        @bot = bot
        @message = message
        @match = match
        @response = ""
        
    reply: (response) ->
        @bot.reply @message, response
        
    send: (response) ->
        @bot.send @message, response
        
    emote: (response) ->
        @bot.emote @message, response
    
module.exports = Message