class Listener
    constructor: (regex, closure) ->
        @regex = regex
        @closure = closure
        
    match: (message) =>
        if matches = message.match @regex
            return matches
        
        false
    
    execute: (message, args...) =>
        @closure message, args
    
module.exports = Listener