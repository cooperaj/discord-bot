{EventEmitter} = require 'events'
Fs = require 'fs'
Path = require 'path'
Async = require 'async'
Discordie = require 'discordie'
HttpClient = require 'scoped-http-client'
Crypto = require 'crypto'
Brain = require './Brain'
Listener = require './Listener'
Message = require './Message'

class Bot extends EventEmitter
    # Recieves messages from a Discord server and sends them off to registered listeners
    #
    # name - A String containing the name of the bot.
    #
    # Returns nothing.
    constructor: (name = "Bot") ->
        @name = name
        
        @brains = Array()        
        @listeners = Array()
        
        @client = new Discordie
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
       
    brain: (server_id) ->
        brains = @brains.filter (brain) =>
            brain.server_id is server_id
        brain = brains[0] ? null
     
    http: (url, options) ->
        HttpClient.create(url, options)
            .header('User-Agent', "Bot/1.0")
            
    random: (items) ->
        items[ Math.floor(Math.random() * items.length) ]
        
    _message: (e) =>
        for listener in @listeners
            if matches = listener.match e.message.content
                listener.execute new Message(@, e.message, matches)
    
    _clientRunning: () =>
        @client.User.setGame { name: process.env.DISCORD_PLAYING } if process.env.DISCORD_PLAYING
        @client.User.edit null, @name if process.env.DISCORD_EMAIL
        @client.User.edit null, null, Fs.readFileSync(process.env.BOT_AVATAR) if process.env.BOT_AVATAR
        @emit "client_ready"
    
    _bootBrains: () =>
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
        
    _loadScripts: () ->
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

module.exports = Bot