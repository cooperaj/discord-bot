import Vue from 'vue';
import store from './vuex/store.js'
import { getUser } from './vuex/getters.js'
import Authentication from './components/authentication.vue'
import ButtonBoard from './components/button-board.vue'

window.onload = function () {
    new Vue({

        el: '#app',

        components: {
            Authentication,
            ButtonBoard
        },

        store,
        vuex: {
            getters: {
                user: getUser
            }
        },

        watch: {
            'user': function(value, oldValue) {
                this.setAvatar(value.user_id, value.user_avatar);
            }
        },

        methods: {
            setAvatar: function(user_id, user_avatar) {
                var bar = document.getElementById('topbar')
                bar.style.backgroundImage = "url('https://cdn.discordapp.com/avatars/"
                    + user_id + "/" + user_avatar + ".jpg')"
            }
        }

    });
};
