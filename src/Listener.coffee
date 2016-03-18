class Listener
    constructor: (regex, closure) ->
        @regex = regex
        @closure = closure
        
    match: (message) =>
        if message.cleanContent.match @regex
            return true
        
        false
    
    execute: (message, args...) =>
        @closure message, args
    
module.exports = Listener