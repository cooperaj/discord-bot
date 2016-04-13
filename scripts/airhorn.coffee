horns = 
    "airhorn_default.mp3": 1000,
    "airhorn_reverb.mp3": 800,
    "airhorn_spam.mp3": 800,
    "airhorn_tripletap.mp3": 800,
    "airhorn_fourtap.mp3": 800,
    "airhorn_distant.mp3": 500,
    "airhorn_echo.mp3": 500,
    "airhorn_clownfull.mp3": 250,
    "airhorn_clownshort.mp3": 250,
    "airhorn_clownspam.mp3": 250,
    "airhorn_highfartlong.mp3": 200,
    "airhorn_highfartshort.mp3": 200,
    "airhorn_midshort.mp3": 100,
    "airhorn_truck.mp3": 10

module.exports = (robot) ->

    robot.hear /airhorn/i, (msg)->
        member = msg.message.member 
        channel = member.getVoiceChannel()    
        
        if channel
            robot.play channel, "audio/" + robot.random horns