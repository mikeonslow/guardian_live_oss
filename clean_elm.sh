cd apps/app_ui/elm
rm -rf  elm-stuff
elm-install
elm-make App.elm --debug --output ../web/static/vendor/app.js
cd ../../../
