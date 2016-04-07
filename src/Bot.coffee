{EventEmitter} = require 'events'
Fs = require 'fs'
Path = require 'path'
Async = require 'async'
Discord = require 'discord.js'
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
    constructor: (name = "PieBot") ->
        @name = name
        
        @brains = Array()        
        @listeners = Array()
        
        @client = new Discord.Client
        @client.on "ready", @_clientRunning
        @client.on "message", @_message      
        
        @on "client_ready", @_bootBrains 
        @on "brains_ready", @_loadScripts

    run: () ->
        @client.login process.env.DISCORD_EMAIL, process.env.DISCORD_PASSWORD, (error, token) =>
            @emit "error", error if error
        
    hear: (regexp, closure) =>
        @listeners.push new Listener regexp, closure  
        
    respond: (regexp, closure) =>
        @hear (@_respondPattern regexp), closure
        
    reply: (message, response) =>
        @client.reply message, response
        
    send: (message, response) =>
        @client.sendMessage message.channel, response
        
    emote: (message, response) =>
        @client.sendMessage message.channel, "*" + response + "*"
       
    brain: (server_id) ->
        brains = @brains.filter (brain) =>
            brain.server_id is server_id
        brain = brains[0] ? null
     
    http: (url, options) ->
        HttpClient.create(url, options)
            .header('User-Agent', "Felchbot/1.0")
            
    random: (items) ->
        items[ Math.floor(Math.random() * items.length) ]
        
    _message: (message) =>
        for listener in @listeners
            if matches = listener.match message
                listener.execute new Message(@, message, matches)
    
    _clientRunning: () =>
        @client.setPlayingGame process.env.DISCORD_PLAYING if process.env.DISCORD_PLAYING
        @emit "client_ready"
    
    _bootBrains: () =>
        brainsToBoot = []
        
        for server in @client.servers 
            brainsToBoot.push (callback) =>
                brain = new Brain @, server.id
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