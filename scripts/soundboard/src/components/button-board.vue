<template>
<div id="buttons">
    <sound-button
        v-for="sound in sounds"
        :key="$key"
        :user="user"
    ></sound-button>
</div>
</template>

<script>
import { getUser } from '../vuex/getters.js';
import SoundButton from './sound-button.vue';

export default {

    components: {
        SoundButton
    },

    data: function() {
        return {
            sounds: null
        }
    },

    vuex: {
        getters: {
            user: getUser
        }
    },

    watch: {
        'user': function(value, oldValue) {
            this.fetchData();
        }
    },

    methods: {
        fetchData: function () {
            var xhr = new XMLHttpRequest()
            var self = this
            xhr.open('GET', '/soundboard/api/sounds')
            xhr.onload = function () {
                self.sounds = JSON.parse(xhr.responseText)
            }
            xhr.send()
        }
    }

}
</script>

<style>
#buttons {
    display: flex;
    flex-direction: row;
    flex-wrap: wrap;
}
</style>
