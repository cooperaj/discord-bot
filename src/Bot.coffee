{EventEmitter} = require 'events'
Fs = require 'fs'
Path = require 'path'
Discord = require 'discord.js'
HttpClient = require 'scoped-http-client'
Crypto = require 'crypto'
Listener = require './Listener'

class Bot extends EventEmitter
    # Recieves messages from a Discord server and sends them off to registered listeners
    #
    # name - A String containing the name of the bot.
    #
    # Returns nothing.
    constructor: (name = "Bot") ->
        @name = name
        
        @listeners = Array()
        
        @client = new Discord.Client
        @client.on "ready", @_running
        @client.on "message", @_message       

    run: () ->
        storedToken = @_loadToken()
        if typeof storedToken is "string"
            @client.loginWithToken(storedToken)
        else
            @client.login process.env.DISCORD_EMAIL, process.env.DISCORD_PASSWORD, (error, token) =>
                Fs.writeFileSync './token.bin', @_encryptToken(token, String(process.env.DISCORD_EMAIL + process.env.DISCORD_PASSWORD)), 'hex'
        
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
        
    http: (url, options) ->
        HttpClient.create(url, options)
            .header('User-Agent', "Felchbot/1.0")
            
    random: (items) ->
        items[ Math.floor(Math.random() * items.length) ]
        
    _running: () =>
        @_loadScripts Path.resolve ".", "scripts"
        @client.setPlayingGame "with himself"
        @emit "ready"
        
    _message: (message) =>
        for listener in @listeners
            if listener.match message
                listener.execute message
        
    _loadScripts: (dir) ->
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
        
    _loadToken: () =>
        try
            et = Fs.readFileSync './token.bin', 'hex'
            token = @_decryptToken et, String(process.env.DISCORD_EMAIL + process.env.DISCORD_PASSWORD)
        catch e
        token
        
    _encryptToken: (token, unpwd) ->
        cipher = Crypto.createCipher 'aes-256-cbc', unpwd
        crypted = cipher.update token, 'utf8', 'hex' 
        crypted += cipher.final 'hex'
	
    _decryptToken: (token, unpwd) ->
        decipher = Crypto.createDecipher 'aes-256-cbc', unpwd
        dec = decipher.update token, 'hex', 'utf8'
        dec += decipher.final 'utf8'

module.exports = Bot