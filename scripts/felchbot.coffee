module.exports = (bot) ->

    bot.hear /ping/i, (msg) ->
        msg.reply "pong"
        
    bot.hear /wibble/i, (msg) ->
        msg.send "https://33.media.tumblr.com/04e99ac3303891b525ba663c518a453d/tumblr_inline_nqrinb6H5v1qegzff_500.gif"
        
    bot.hear /baby.*monkey/i, (msg) ->
        msg.send "https://www.youtube.com/watch?v=5_sfnQDr1-o"
        
    bot.hear /badum tish/i, (msg) ->
        msg.send "http://i.imgur.com/BbgL7x3.gif"