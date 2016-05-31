{EventEmitter} = require 'events'
_ = require 'lodash'
Fs = require 'fs'
Lame = require 'lame'
Path = require 'path'
Async = require 'async'
Crypto = require 'crypto'
Express = require 'express'
Discordie = require 'discordie'
BodyParser = require 'body-parser'
HttpClient = require 'scoped-http-client'
Brain = require './Brain'
Listener = require './Listener'
Message = require './Message'

class Bot extends EventEmitter
    # Recieves messages from a Discord server and sends them off to registered listeners
    #
    # @param name A String containing the name of the bot.
    constructor: (name = "Bot") ->
        @name = name
        
        @brains = Array()        
        @listeners = Array()
        
        @client = new Discordie { autoReconnect: true }
        @client.Dispatcher.on "GATEWAY_READY", @_clientRunning
        @client.Dispatcher.on "MESSAGE_CREATE", @_message      
        
        @on "client_ready", @_bootBrains 
        @on "brains_ready", @_loadScripts
        
    run: () ->
        if process.env.DISCORD_TOKEN
            @client.connect { token: process.env.DISCORD_TOKEN }
        else
            @client.connect { 
                email: process.env.DISCORD_EMAIL, 
                password: process.env.DISCORD_PASSWORD
            }
            
    # Lets a script register a listener that responds when it spots text in
    # amongst the message contents.
    #
    # @param regexp The regular expression to match the message contents on
    # @param closure The code to execute when a match is made 
    hear: (regexp, closure) =>
        @listeners.push new Listener regexp, closure  
        
    respond: (regexp, closure) =>
        @hear (@_respondPattern regexp), closure
        
    reply: (message, response) =>
        message.reply response
        
    send: (message, response) =>
        message.channel.sendMessage response
        
    emote: (message, response) =>
        message.channel.sendMessage "*" + response + "*"
        
    # Plays an MP3 encoded file to the channel specified.
    #
    # @param channel The audio channel to which you want the file played
    # @param mp3Path The path to the mp3 file that you want to play
    play: (channel, mp3Path) ->
        return if channel.type is not 'voice'
    
        mp3decoder = new Lame.Decoder
        mp3 = Fs.createReadStream mp3Path
        mp3.pipe mp3decoder
        
        mp3decoder.on 'format', (pcmfmt) ->
            options = {
                frameDuration: 60,
                sampleRate: pcmfmt.sampleRate,
                channels: pcmfmt.channels,
                float: false
            }
            
            channel.join().then (info, err) ->
                return if !info            
                            
                encoderStream = info.voiceConnection.getEncoderStream options
                return if !encoderStream

                encoderStream.once 'unpipe', () -> 
                    mp3.destroy() # close descriptor

                mp3decoder.pipe encoderStream
                mp3decoder.once 'end', () ->
                    setTimeout () -> 
                        channel.leave()
                    , 1000
                    
            .catch (err) ->
                console.log "Bot: Error whilst playing mp3: #{err}"
                channel.leave()
       
    brain: (server_id) ->
        brains = @brains.filter (brain) ->
            brain.server_id is server_id
        brain = brains[0] ? null
     
    http: (url, options) ->
        HttpClient.create(url, options)
            .header('User-Agent', "Bot/1.0")
            
    random: (items) ->
        if _.isArray items
            items[ Math.floor(Math.random() * items.length) ]
        else
            @_weightedRandom items
           
    _weightedRandom: (items) ->
        sum = 0
        collection = _.keys(items).reduce (previous, current) -> 
            sum += items[current]
            previous.push { value: current, weight: sum }
            previous
        , []
        
        sortedCollection = _.orderBy collection, 'weight'
        randomValue = Math.floor Math.random() * sum
        
        i = 0
        while i < sortedCollection.length
            return sortedCollection[i].value if randomValue < sortedCollection[i].weight
            i++
        
    _message: (e) =>
        for listener in @listeners
            if matches = listener.match e.message.content
                listener.execute new Message(@, e.message, matches)
    
    _clientRunning: =>
        @client.User.setGame { name: process.env.DISCORD_PLAYING } if process.env.DISCORD_PLAYING
        @client.User.edit null, @name if process.env.DISCORD_EMAIL
        @client.User.edit null, null, Fs.readFileSync(process.env.BOT_AVATAR) if process.env.BOT_AVATAR
        
        @_setupExpress()
        
        @emit "client_ready"
    
    _bootBrains: =>
        brainsToBoot = []
        
        @client.Guilds.forEach (guild) =>
            brainsToBoot.push (callback) =>
                brain = new Brain @, guild.id
                brain.on "ready", callback
                brain.connect()
                
                @brains.push brain
            
        Async.parallel brainsToBoot, (err, results) =>
            @emit "brains_ready"
            @brains
        
    _loadScripts: ->
        dir = Path.resolve ".", "scripts"
        if Fs.existsSync dir
            for file in Fs.readdirSync(dir).sort()
                ext  = Path.extname file
                full = Path.join dir, Path.basename file, ext
                try
                    script = require full

                    if typeof script is 'function'
                        script @
                    else
                        console.log "Expected #{full} to assign a function to module.exports, got #{typeof script}"

                catch error
                    console.log "Unable to load #{full}: #{error.stack}"
                    process.exit 1
                    
        @emit "ready"
                    
    _respondPattern: (regex) ->
        re = regex.toString().split('/')
        re.shift()
        modifiers = re.pop()

        pattern = re.join '/'
        name = @name.replace /[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&'

        newRegex = new RegExp(
            "^\\s*[@]?#{name}[:,]?\\s*(?:#{pattern})",
            modifiers
        )
    
    # Setup the Express server's defaults.
    #
    _setupExpress: ->
        user    = process.env.EXPRESS_USER
        pass    = process.env.EXPRESS_PASSWORD
        port    = process.env.EXPRESS_PORT or process.env.PORT or 8080
        address = process.env.EXPRESS_BIND_ADDRESS or process.env.BIND_ADDRESS or '0.0.0.0'

        app = Express()

        app.use (req, res, next) =>
            res.setHeader "X-Powered-By", "discord-bot/#{@name}"
            next()

        app.use Express.basicAuth user, pass if user and pass
        app.use Express.query()

        app.use BodyParser.json()
        app.use BodyParser.urlencoded()

        @server = app.listen(port, address)
        @router = app
        
        console.log "Express: Listening on #{address}:#{port}"

module.exports = Bot