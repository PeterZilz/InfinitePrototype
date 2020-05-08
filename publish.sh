#! /bin/bash

if ! test -f ./publish.config.user ; then
    echo "scpTargetFolder=user@host.com:/path/to/folder/" > ./publish.config.user
    echo "Missing config file 'publish.config.user' created."
else
    ./optimize-elm.sh

    # executes all variable definitions in the config file:
    . publish.config.user

    # Temporarily append an unique update on the service worker on each deployment.
    # This ensures an update of the service worker and susequently an update on the cached assets.
    cp ./static/service-worker.js ./service-worker.js.tmp
    echo "/* $(git rev-parse --short HEAD), $(date) */" >> ./static/service-worker.js

    scp -r static/* $scpTargetFolder

    rm ./static/service-worker.js
    mv ./service-worker.js.tmp ./static/service-worker.js
fi
