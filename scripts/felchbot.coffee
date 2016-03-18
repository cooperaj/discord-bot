module.exports = (bot) ->

    bot.hear /ping/i, (message) ->
        bot.reply message, "pong"
        
    bot.hear /wibble/i, (message) ->
        bot.send message, "https://33.media.tumblr.com/04e99ac3303891b525ba663c518a453d/tumblr_inline_nqrinb6H5v1qegzff_500.gif"
        
    bot.hear /I like pie/i, (message) ->
        bot.emote message, "makes a freshly baked pie"
        
    bot.hear /baby.*monkey/i, (message) ->
        bot.send message, "https://www.youtube.com/watch?v=5_sfnQDr1-o"