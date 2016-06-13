<template>
<div id="logindialog" class="row" v-if="!user">
    <div class="col-sm-8 col-sm-offset-2">
        <p>To access the soundboard you will need to login using your Discord credentials. Don't worry, we let Discord
            do all the work and so won't see your precious.</p>
        <a href="/auth" class="btn btn-default" role="button">Login</a>
    </div>
</div>
</template>

<script>
import { getUser } from '../vuex/getters.js';
import { updateUser } from '../vuex/actions.js';

export default {

    vuex: {
        actions: {
            updateUser: updateUser
        },
        getters: {
            user: getUser
        }
    },

    created: function() {
        var cookieValue = document.cookie.replace(/(?:(?:^|.*;\s*)sb-user\s*\=\s*([^;]*).*$)|^.*$/, "$1")
        if (cookieValue) {
            this.updateUser(JSON.parse(decodeURIComponent(cookieValue)));
        }
    },
}
</script>

<style>
#logindialog .btn {
    margin-left: 0;
}
</style>
