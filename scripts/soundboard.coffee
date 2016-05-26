sounds =
    "Random Airhorn": 
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
    "Random Cena":
        "jc_airhorn.mp3": 250,
        "jc_echo.mp3": 250,
        "jc_full.mp3": 250,
        "jc_jc.mp3": 250,
        "jc_nameis.mp3": 250,
        "jc_spam.mp3": 250
    "Wombo Combo": 
        "wombo_combo.mp3": 1

module.exports = (robot) ->

    robot.router.get '/soundboard', (req, res) ->
        res.send JSON.stringify sounds
        
    robot.router.get '/soundboard/:id/:sound', (req, res) ->
        user = robot.client.Users.get req.params.id
        sound = sounds[req.params.sound]

        if not sound
            res.status(404).send "sound not found"
            return 
        
        member = null
        robot.client.Guilds.forEach (guild) =>
            
            if member = user.memberOf(guild)
                if channel = member.getVoiceChannel()      
                    robot.play channel, "audio/" + robot.random sound
                    res.send "ok"
                    return
                    
        if not res.headersSent
            res.status(404).send "user not found"