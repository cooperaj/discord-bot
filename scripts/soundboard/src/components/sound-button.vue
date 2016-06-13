<template>
<button name="sound"
    class="btn btn-default"
    id="{{ key }}"
    value="{{ key }}"
    v-on:click="playSound(key)">{{{ key }}}</button>
</template>

<script>

export default {

    props: [
        'key',
        'user'
    ],

    methods: {
        playSound: function(identifier) {
            var xhr = new XMLHttpRequest()
            xhr.open('GET', '/soundboard/api/sounds/' + encodeURIComponent(identifier) + '/' + this.user.user_id)
            xhr.onload = function () {
                // don't do anything just yet
            }
            xhr.send()
        }
    }
}
</script>

<style>
.btn {
    margin: 0.4em;
    border-radius: 0;
    flex-grow: 1;
}
</style>
