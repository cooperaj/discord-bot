cenas = 
    "jc_airhorn": 250,
    "jc_echo": 250,
    "jc_full": 250,
    "jc_jc": 250,
    "jc_nameis": 250,
    "jc_spam": 250

module.exports = (robot) ->

    robot.hear /cena/i, (msg)->
        member = msg.message.member 
        channel = member.getVoiceChannel()    
        
        if channel
            robot.play channel, "audio/" + robot.random cenas