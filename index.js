"use strict";

require('dotenv').config({silent: true});
require('coffee-script/register');
var Bot = require('./src/Bot');

process.on('uncaughtException', function (err) {
    console.error('An uncaughtException was found, the bot will shutdown.');
    console.error(err);
    process.exit(1);
});

var bot_instance = new Bot(process.env.BOT_NAME || null);

bot_instance.once('ready', function() {
    console.log('Bot "' + bot_instance.name + '" running...');
});

bot_instance.on('error', function(error) {
    console.error('Bot encountered an error and could not start.');
})

bot_instance.run();
