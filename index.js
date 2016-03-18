"use strict";

require('dotenv').config();
require('coffee-script/register');
const Bot = require('./src/Bot');

let instance = new Bot(process.env.BOT_NAME);

instance.once('ready', () => {
    console.log('Bot "' + process.env.BOT_NAME + '" running...');
});

instance.run();