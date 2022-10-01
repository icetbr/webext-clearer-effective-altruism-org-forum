#!/bin/bash

PATH=$PATH:../../node_modules/.bin
set -a && . ./.env && set +a

## NOTES
# - web-ext lint is always needed because if the extension doesn’t meet the standards, it is rejected by the browser store
# - I lint only the `dist`` folder because I rely on the IDE to lint the `src` folder

#NODE
_node () { NODE_NO_WARNINGS=1 node --experimental-fetch "$@" ;}
a_nodei () { _node --inspect-brk=9231 "$@" ;}
_nodei () { _node --inspect=9231 "$@" ;}
_nodemon          () { _nodei nodemon -x "printf \"\033c\";${!1}" ;} # ../../node_modules/nodemon/bin/nodemon.js
# dev () { ./node_modules/nodemon/bin/nodemon.js -x "printf \"\033c\"; NODE_NO_WARNINGS=1 node --inspect-brk=9231 --experimental-fetch src/fetchCommentsPage.js" ;}
# dev () { _nodemon ./src/fetchCommentsPage.js ;}
# dev () { NODE_NO_WARNINGS=1 ./node_modules/nodemon/bin/nodemon.js --experimental-fetch -x "printf \"\033c\";src/fetchCommentsPage.js" ;}
# xtest        () { NODE_NO_WARNINGS=1 mocha --experimental-fetch --inline-diffs --bail --leaks --reporter min -r chai/register-expect.js ;}
# test        () { NODE_NO_WARNINGS=1 mocha --experimental-fetch --inline-diffs --bail --leaks --reporter min ;}
test        () { _node mocha --inline-diffs --bail --leaks --reporter min "$@" ;}
testi        () { _nodei mocha --inline-diffs --bail --leaks --reporter min "$@" ;}


################
## MAINTAINANCE
################
newRepo () {
    if [ -z "$1" ]; then echo "Usage: run newRepo repo-name"; exit 1; fi

    curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos -d '{"name":"'$1'"}'
    git init
    git branch -m main
    git remote add origin git@github.com:icetbr/$1.git
}
sync             () { if [ -n "$(diff ../utils/$1 $1)" ]; then code --diff --wait ../utils/$1 $1 ; fi       ;}
syncConfigs      () { sync .eslintrc.json && sync .gitignore && sync run.sh && sync CONTRIBUTING.md         ;}
spellDeps        () { _node -e "import('../utils/src/listDependencies.js').then(m => m.listDependencies())" ;}
spell            () { cspell src/*.js README.md                                                             ;}
syncMetadata     () { _node -e "import('../utils/src/deploy.js').then(m => m.syncMetadata())"               ;}
icons            () { _node -e "import('../utils/src/favicons.js')"                                         ;}
editIcon         () { ~/tools/Inkscape.AppImage media/icon.svg                                              ;}


################
## WEBEXT
################

ffUploadUrl=https://addons.mozilla.org/en-US/developers/addon/submit/upload-listed

## TEMP
# - the code is not ready to be airbnb-lintable
_lintAirbnb     () { eslint dist && web-ext lint ;}
_lintJustWebext () { web-ext lint                ;}
# publishChrome    () { build && adjustManifestV3 && chrome-webstore-upload upload --source dist --extension-id $WEBEXT_ID --client-id $CHROME_KEY --client-secret $CHROME_SECRET --refresh-token $CHROME_REFRESH_TOKEN           ;}

## SUPPORT
uploadFf         () { web-ext sign --channel= listed --api-key=$FIREFOX_KEY --api-secret=$FIREFOX_SECRET --id=$WEBEXT_ID                                                                  ;}
uploadChrome     () { chrome-webstore-upload publish --source dist --extension-id $WEBEXT_ID --client-id $CHROME_KEY --client-secret $CHROME_SECRET --refresh-token $CHROME_REFRESH_TOKEN ;}
zipSrc           () { cd dist && zip -r -FS ../$WEBEXT_ID *                                     ;}
lint             () { _lintJustWebext "$@"                                                      ;} # see NOTES
copyFilesToDist  () { cp -R manifest.json media/icons dist                                      ;}
adjustManifestV3 () { sed -i 's/2/3/' dist/manifest.json && sed -i '18,23d' dist/manifest.json  ;}
bundle           () { rollup --config rollup.config.js                                          ;}

## PUBLISH
build            () { bundle && copyFilesToDist && lint          ;}
firstRun         () { build && zipSrc && firefox $ffUploadUrl    ;}
publishFirefox   () { build && uploadFf                          ;}
publishChrome    () { build && adjustManifestV3 && uploadChrome  ;}

## DEV
watch             () { rollup --config rollup.config.js --watch  ;}

"$@"
