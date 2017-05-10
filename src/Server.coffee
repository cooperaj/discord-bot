{EventEmitter} = require 'events'
Express = require 'express'
Discordie = require 'discordie'
BodyParser = require 'body-parser'
Session = require 'express-session'
RedisStore = require('connect-redis')(Session)
HttpClient = require 'scoped-http-client'

class Server extends EventEmitter

    constructor: (name)->
        @port    = process.env.SERVER_PORT or 8080
        @address = process.env.SERVER_BIND_ADDRESS or '0.0.0.0'

        @app = Express()

        @app.set('trust proxy', 'loopback, uniquelocal') if process.env.NODE_ENV is 'production'

        @app.use (req, res, next) =>
            res.setHeader "X-Powered-By", "discord-bot/#{name}"
            next()

        @app.use Express.query()
        @app.use Express.static 'public'

        @app.use BodyParser.json()
        @app.use BodyParser.urlencoded { extended: false }

        @_setupSession() if process.env.AUTH_CLIENT_ID and process.env.AUTH_CLIENT_SECRET
        @_setupAuth() if process.env.AUTH_CLIENT_ID and process.env.AUTH_CLIENT_SECRET

        @server = @app.listen(@port, @address)
        @router = @app

        console.log "Express: Listening on #{@address}:#{@port}"

    _setupSession: ->
        redis_url = if process.env.REDIS_URL?
            process.env.REDIS_URL
        else
            'redis://localhost:6379'

        @app.use Session {
            store: new RedisStore { url: redis_url }
            secret: process.env.SESSION_SECRET ? 'secretsessionid'
            resave: false
            saveUninitialized: false
        }

    # Sets up the required endpoints for oauth authorisation against the discord service.
    _setupAuth: ->
        callback_port = if process.env.NODE_ENV is 'production' then '' else ':' + @port
        callback_protocol = if process.env.NODE_ENV is 'production' then 'https' else 'http'

        oauth2 = require('simple-oauth2') (
            clientID: process.env.AUTH_CLIENT_ID
            clientSecret: process.env.AUTH_CLIENT_SECRET
            site: 'https://discordapp.com'
            tokenPath: '/api/oauth2/token'
            authorizationPath: '/api/oauth2/authorize' )

        # Initial page redirecting to Github
        @app.get '/auth', (req, res) =>
            if not req.secure and process.env.NODE_ENV is 'production'
                req.session.returnTo = req.header 'Referer'
                res.redirect "#{callback_protocol}://#{req.hostname}#{callback_port}/auth"

            # Authorization uri definition
            authorization_uri = oauth2.authCode.authorizeURL {
                redirect_uri: "#{callback_protocol}://#{req.hostname}#{callback_port}/auth/callback"
                scope: 'identify' }

            req.session.returnTo = req.header 'Referer'
            res.redirect authorization_uri

        # Callback service parsing the authorization token and asking for the access token
        @app.get '/auth/callback', (req, res) =>
            code = req.query.code

            saveToken = (error, result) =>
                if error
                    console.log 'Express: Access Token Error', error
                    res.redirect req.session.returnTo
                    return

                @_fetchUserInfo (oauth2.accessToken.create result), (error, userres, body) ->
                    console.log error if error

                    user = JSON.parse body
                    res.cookie 'sb-user', JSON.stringify {
                        user_id: user.id
                        user_name: user.username
                        user_avatar: user.avatar
                    }
                    res.redirect req.session.returnTo

            oauth2.authCode.getToken {
                code: code
                redirect_uri: "#{callback_protocol}://#{req.hostname}#{callback_port}/auth/callback"
            }, saveToken

    _fetchUserInfo: (token, fn) ->
        HttpClient.create('https://discordapp.com/api/users/@me')
            .header('User-Agent', "#{@name} (https://github.com/cooperaj/discord-bot, 1.0)")
            .header('Authorization', "Bearer #{token.token.access_token}")
            .get() fn

module.exports = Server
