Express = require 'express'

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
    "Random Quake":
        "quake_dominating.mp3": 250,
        "quake_headshot.mp3": 250,
        "quake_humiliation.mp3": 250,
        "quake_multikill.mp3": 250,
        "quake_rampage.mp3": 250,
        "quake_unstoppable.mp3": 250
    "2sad4me":
        "2sad4me.mp3": 1
    "2sed4airhorn":
        "2sed4airhorn.mp3": 1
    "Get Noscoped":
        "get_noscoped.mp3": 1
    "OooooooohMyGooood":
        "oooooooohmygooood.mp3": 1
    "Oh baby a triple":
        "Oh_baby_a_triple.mp3": 1
    "Shots Fired":
        "shots_fired.mp3": 1
    "Skrillex Scary":
        "skrillex_scary.mp3": 1
    "Spooky":
        "spooky.mp3": 1
    "Surprise Motherfucker":
        "Surprise_Motherfucker.mp3": 1
    "Tactical Nuke":
        "tactical_nuke.mp3": 1
    "Wombo Combo":
        "wombo_combo.mp3": 1
    "Headshot":
        "quake_headshot.mp3": 1
    "Humiliation":
        "quake_humiliation.mp3": 1
    "Multi Kill":
        "quake_multikill.mp3": 1
    "Rampage":
        "quake_rampage.mp3": 1,
    "Unstoppable":
        "quake_unstoppable.mp3": 1
    "What is love?":
        "what_is_love.mp3": 1
    "Bye, have a great time":
        "bye_have_a_great_time": 1
    "It was at this moment...":
        "it_was_at_this_moment.mp3": 1


module.exports = (robot) ->

    robot.router.use '/soundboard', Express.static __dirname + '/soundboard'

    robot.router.get '/soundboard/api/sounds', (req, res) ->
        res.send JSON.stringify sounds

    robot.router.get '/soundboard/api/sounds/:sound/:id', (req, res) ->
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
