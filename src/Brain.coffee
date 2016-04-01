{EventEmitter} = require 'events'
Url = require 'url'
Redis = require 'redis'

class Brain extends EventEmitter
    # Represents somewhat persistent storage for the robot. Extend this.
    #
    # Returns a new Brain with no external storage.
    constructor: (robot, server_id) ->  
        @robot = robot 
        @server_id = server_id
        @redis_url = if process.env.REDIS_URL?
            process.env.REDIS_URL
        else
            'redis://localhost:6379'
        
        @data =
            users:    { }
            _private: { server_id: server_id }

        @autoSave = false
                
        # start up the timed saving of data
        @resetSaveInterval 5


    connect: () ->
        info    = Url.parse @redis_url, true
        @client = if info.auth?
                Redis.createClient(info.port, info.hostname, {no_ready_check: true}) 
            else 
                Redis.createClient(info.port, info.hostname)
        @prefix = info.path?.replace('/', '') or @server_id
        
        @client.on "error", (err) ->
            if /ECONNREFUSED/.test err.message
            else
                console.log err.stack
        
        @client.on "connect", =>
            console.log "Brain: Successfully connected to Redis"
            @getData() if not info.auth
            
        if info.auth
            @client.auth info.auth.split(":")[1], (err) =>
            if err
                console.log "Brain: Failed to authenticate to Redis"
            else
                console.log "Brain: Successfully authenticated to Redis"
                @getData()


    getData: () ->
        @client.get "#{@prefix}:storage", (err, reply) =>
            if err
                throw err
            else if reply
                console.log "Brain: Data for #{@prefix} brain retrieved from Redis"
                @mergeData JSON.parse(reply.toString())
            else
                console.log "Brain: Initializing new data for #{@prefix} brain"
                @mergeData {}

            @setAutoSave true
            @emit "ready"

    # Public: Store key-value pair under the private namespace and extend
    # existing @data before emitting the 'loaded' event.
    #
    # Returns the instance for chaining.
    set: (key, value) ->
        if key is Object(key)
            pair = key
        else
            pair = {}
            pair[key] = value

        extend @data._private, pair
        @emit 'loaded', @data
        @

    # Public: Get value by key from the private namespace in @data
    # or return null if not found.
    #
    # Returns the value.
    get: (key) ->
        @data._private[key] ? null

    # Public: Remove value by key from the private namespace in @data
    # if it exists
    #
    # Returns the instance for chaining.
    remove: (key) ->
        delete @data._private[key] if @data._private[key]?
        @

    # Public: Saves the data
    #
    # Returns nothing.
    save: ->
        @client.set "#{@prefix}:storage", JSON.stringify @data

    # Public: Emits the 'close' event so that 'brain' scripts can handle closing.
    #
    # Returns nothing.
    close: ->
        clearInterval @saveInterval
        @save()
        @client.quit()

    # Public: Enable or disable the automatic saving
    #
    # enabled - A boolean whether to autosave or not
    #
    # Returns nothing
    setAutoSave: (enabled) ->
        @autoSave = enabled

    # Public: Reset the interval between save function calls.
    #
    # seconds - An Integer of seconds between saves.
    #
    # Returns nothing.
    resetSaveInterval: (seconds) ->
        clearInterval @saveInterval if @saveInterval
            
        @saveInterval = setInterval =>
            @save() if @autoSave
        , seconds * 1000

    # Public: Merge keys loaded from a DB against the in memory representation.
    #
    # Returns nothing.
    #
    # Caveats: Deeply nested structures don't merge well.
    mergeData: (data) ->
        for k of (data or { })
            @data[k] = data[k]

        @emit 'loaded', @data

    # Public: Get an Array of User objects stored in the brain.
    #
    # Returns an Array of User objects.
    users: ->
        @data.users

    # Public: Get a User object given a unique identifier.
    #
    # Returns a User instance of the specified user.
    userForId: (user_id, options) ->
        user = @data.users[user_id]
        unless user
            user = options
            @data.users[user_id] = user

        user

    # Private: Extend obj with objects passed as additional args.
    #
    # Returns the original object with updated changes.
    extend = (obj, sources...) ->
        for source in sources
            obj[key] = value for own key, value of source
        obj

module.exports = Brain