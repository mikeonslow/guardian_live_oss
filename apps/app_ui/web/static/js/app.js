(function () {
    var startup = function () {
        // return;

        // Start the Elm App.

        function initFlags() {
            var d = new Date();
            var n = d.getTime();

            var flags = {
                userData: localStorage.appUser || null,
                currentTimestamp: n
            }

            console.log(flags);

            return flags;
        }

        const elmDiv = document.getElementById('elm-main')
            , elmApp = Elm.App.embed(elmDiv,initFlags())

        var openWindows = {};

        window.addEventListener('storage', function (e) {
            console.log("storage changed in other window", e);
            elmApp.ports.localStorageChanged.send(e);
            handleNewWindowActions(openWindows);
        }, false);

        elmApp.ports.setSecurityToken.subscribe(function(token)
        {
            localStorage.setItem('app-jwt', token);
            console.log('token has been cached');
            console.log(localStorage.getItem('app-jwt'));
        });

        elmApp.ports.setUserCache.subscribe(function(user)
        {
            localStorage.appUser = JSON.stringify(user);
            console.log('appUser has been cached', typeof user, user);
            console.log(localStorage.appUser);

            console.log('appUser', localStorage.appUser.username);

        });

        elmApp.ports.clearUserCache.subscribe(function(nothing)
        {
            localStorage.removeItem('appUser');
            console.log("appUser", localStorage.getItem('appUser'));
        });

        elmApp.ports.getSecurityToken.subscribe(function(nothing)
        {
            var token = '';

            if('string' == typeof localStorage.getItem('app-jwt')
                && localStorage.getItem('app-jwt')) {
                token = localStorage.getItem('app-jwt');
            }

            console.log('getSecurityToken', {
                "guardian_token": token
            });

            elmApp.ports.sendSecurityToken.send({
                "guardian_token": token
            });
        });

        elmApp.ports.clearSecurityToken.subscribe(function(nothing)
        {
            console.log('clearSecurityToken');
            localStorage.removeItem('app-jwt');
            console.log('app-jwt', localStorage.getItem('app-jwt'));
        });

        elmApp.ports.setUsernameCache.subscribe(function(username)
        {
            localStorage.setItem('app-cache-username', true);
            localStorage.setItem('app-username', username);
            console.log('username has been cached');
            console.log(localStorage.getItem('app-cache-username'));
            console.log(localStorage.getItem('app-username'));
        });

        elmApp.ports.getUsernameCache.subscribe(function(nothing)
        {
            console.log("getUsernameCache");

            var username = '';
            var cacheEnabled = false;

            if('string' == typeof localStorage.getItem('app-username')
                && localStorage.getItem('app-cache-username')) {
                username = localStorage.getItem('app-username');
                cacheEnabled = true;
            }

            console.log('getUsernameCache', {
                "username": username,
                "cacheEnabled": cacheEnabled
            });

            // window.setTimeout(function () {
                elmApp.ports.sendUsernameCache.send({
                    "username": username,
                    "cacheEnabled": cacheEnabled
                });
            // }, 2000);

        });

        elmApp.ports.clearUsernameCache.subscribe(function(nothing)
        {
            console.log('clearUsernameCache');

            localStorage.removeItem('app-cache-username');
            localStorage.removeItem('app-username');

            console.log(localStorage.getItem('app-cache-username'));
            console.log(localStorage.getItem('app-username'));
        });

        elmApp.ports.sendWindowCommand.subscribe(function(command)
        {
            console.log(command);

            switch(command.action) {
                case "open":
                    openWindow(command, openWindows, elmApp);
                    break;
                case "close":
                    closeWindow(command.url, openWindows);
                    break;
                default:
                    console.log("unhandled action", command.action);
            }
        });

        elmApp.ports.sendToLocalStorage.subscribe(function(data)
        {
            console.log("updating local storage", data);

            var key = data.key;
            var currentValue = localStorage.getItem(key);

            var changeEvent = { key : key, oldValue : currentValue, url : "self" };

            switch(data.action) {
                case "set":
                    localStorage.setItem(key, data.value);
                    changeEvent.newValue = data.value;
                    break;
                case 'remove':
                    localStorage.removeItem(key);
                    changeEvent.newValue = null;
                    break;
                default:
                    console.log("unhandled action", data.action);
                    changeEvent.newValue = currentValue;
            }

            if (currentValue !== changeEvent.newValue) {
                elmApp.ports.localStorageChanged.send(changeEvent);
            }
        });

        var clipboard = new Clipboard('.copy-on-click');
    };

    window.addEventListener('load', startup, false);
}());

function openWindow(config, openWindows, elmApp) {
    var existingWindow = openWindows[config.url];
    if (existingWindow != null) {
        existingWindow.focus();
        return;
    }
    console.log("opening window", config.name);
    var newWindow = window.open(config.url, config.name, config.options);
    openWindows[config.url] = newWindow;

    newWindow.addEventListener('load', function() {
        newWindow.addEventListener('storage', function (e) {
            console.log("storage event occured in main window", e);
            elmApp.ports.localStorageChanged.send(e);
        }, false);
    });

    newWindow.addEventListener("beforeunload", function (e) {
        closeWindow(config.url, openWindows);
    });

    console.log(config);
    var height = convertSize(config.height, window.screen.height);
    var width = convertSize(config.width, window.screen.width);

    newWindow.resizeTo(width, height);
    newWindow.moveTo(0,0);
}

function convertSize(params, max) {
    switch (params.type) {
        case 0 :
            return params.value;
        case 1 :
            return (params.value / 100) * max;
    }
}

function closeWindow(url, openWindows) {
    console.log("closing window", url);
    var existingWindow = openWindows[url];
    console.log("found window is ", existingWindow);
    if (existingWindow != null) {
        existingWindow.close();
        openWindows[url] = null;
    }

}

//borrowing from jQuery
function isVisible(e) {
    return !!( e.offsetWidth || e.offsetHeight || e.getClientRects().length );
}

