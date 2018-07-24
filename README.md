# Sample application demonstraiting permission managment for guardian 

To demonstrate capability of [guardian fork](https://github.com/borodark/guardian/tree/feature/live_permissions).
The application permissions
* available at runtime from GenServer state.
* are loaded from DB at application startup. 
* altered in UI sent to be persisted after GenServer state is updated. 

##Up and Running

Create mysql database named `app` and user 'root'@'%' with password 123.
Load initial db dump with tables fro sql directory.
The username to login with: `io` password: `password`

###Prerequisites

####Elixir
* Install Elixir 1.6.0 (https://elixir-lang.org/install.html)

####Erlang
* Should be installed as part of Elixir install but verify you're using OTP version 20.* (or higher)

####Elm
* `$npm install -g elm`
* `$npm install -g elm-format@exp`
* `$npm install -g elm-github-install`

####Project

* Clone project 
* `$mix deps.get`
* `$cd apps/app_ui/`
* `$npm install`
* `$cd ../..`
* `$mix compile`
* `$mix elm.dev` (this steps may take a few minutes the first time)
* `$./start` (or `mix phx.server` if you're on Windows)



