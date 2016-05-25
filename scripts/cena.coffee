cenas = 
    "jc_airhorn.mp3": 250,
    "jc_echo.mp3": 250,
    "jc_full.mp3": 250,
    "jc_jc.mp3": 250,
    "jc_nameis.mp3": 250,
    "jc_spam.mp3": 250

module.exports = (robot) ->

    robot.hear /cena/i, (msg)->
        member = msg.message.member 
        channel = member.getVoiceChannel()    
        
        if channel
            robot.play channel, "audio/" + robot.random cenas