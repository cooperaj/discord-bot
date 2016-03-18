module.exports = (robot) ->

    robot.respond /corgi me/i, (msg) ->
        robot.http("http://corginator.herokuapp.com/random")
            .get() (err, res, body) ->
                robot.send msg, JSON.parse(body).corgi

#   robot.respond /corgi bomb( (\d+))?/i, (msg) ->
#     count = msg.match[2] || 5
#     robot.http("http://corginator.herokuapp.com/bomb?count=" + count)
#       .get() (err, res, body) ->
#         robot.send corgi for corgi in JSON.parse(body).corgis