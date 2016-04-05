_ = require 'lodash'

class TwitchWatcher 
    constructor: (robot, server_id) ->
        @server_id = server_id
        @robot = robot
        @channels = robot.brain(server_id).get('tw_channels') ? @robot.brain(@server_id).set('tw_channels', []).get('tw_channels')
        robot.on "ts_start", @notifyStreamStart

    run: () =>
        setTimeout @fetchStreams, 10 * 1000
        
    fetchStreams: () =>
        query = @_getChannelsAsString()
        
        @robot.http "https://api.twitch.tv/kraken/streams?channel=#{query}"
            .get() (err, res, body) =>
                @channels = @channels.map (channel) =>
                    for stream in JSON.parse(body).streams
                        if channel.name is stream.channel.name # channel is online according to twitch
                            if channel.online is false # we think it's offline
                                channel.online = true
                                @robot.emit "ts_start", channel.channel_id, channel.user_id, stream.channel.url
                            return channel # return channel as online
                            
                    # hitting here indicates it's not online according to twitch (i.e. absent)
                    channel.online = false
                    channel  
                    
                # array.map creates a new array so we need to force it back into the brain
                @robot.brain(@server_id).set 'tw_channels', @channels              
        
        setTimeout @fetchStreams, 60 * 1000

    notifyStreamStart: (channel_id, user_id, url) =>
        @robot.client.sendMessage channel_id, "<@#{user_id}> has started streaming: #{url}"
        
    addChannel: (channel_id, user_id, name) =>
        @removeChannel channel_id, user_id
        @channels.push({
            channel_id: channel_id
            user_id: user_id, 
            "name": name, 
            online: false
        })
        
    removeChannel: (channel_id, user_id) =>
        @channels = @channels.filter (channel) =>
            !(channel.channel_id is channel_id and 
                channel.user_id is user_id)
                
        # array.filter creates a new array so we need to force it back into the brain
        @robot.brain(@server_id).set 'tw_channels', @channels
        
    _getChannelsAsString: () =>
        channelString = (channel.name for channel in (_.uniqBy @channels, 'name')).toString()
            

module.exports = (robot) ->
    tw = new TwitchWatcher robot, robot.client.servers[0].id
    tw.run()
    
    robot.respond /add my twitch channel ([a-zA-Z0-9_]{3,25})/i, (msg) ->
        tw.addChannel msg.message.channel.id, msg.message.author.id, msg.match[1]
        msg.reply "I added your channel - #{msg.match[1]}"
        
    robot.respond /remove my twitch channel/i, (msg) ->
        tw.removeChannel msg.message.channel.id, msg.message.author.id
        msg.reply "I removed your channel"