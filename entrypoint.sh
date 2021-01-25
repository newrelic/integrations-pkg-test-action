#!/usr/bin/env bash

set -o errexit
set -o pipefail

if [[ -z $POST_INSTALL ]]; then
    POST_INSTALL="
    test -e /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION}
    /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION} -show_version 2>&1 | grep -e $TAG
    "
fi
POST_INSTALL="$POST_INSTALL
$POST_INSTALL_EXTRA"

errors=0

function build_and_test() {
    if [[ $1 = "true" ]]; then upgradesuffix="-upgrade"; fi
    dockertag="$INTEGRATION:$distro-$TAG$upgradesuffix"

    if ! docker build -t "$dockertag" -f "$GITHUB_ACTION_PATH/dockerfiles-test/Dockerfile-$distro" --build-arg TAG="${TAG}" --build-arg INTEGRATION="${INTEGRATION}" --build-arg UPGRADE=$1 .; then
        echo "❌ Clean install failed on $distro" 1>&2
        return 1
    fi
    echo "✅ Installation for $dockertag succeeded"

    echo "ℹ️ Running post-installation checks"
    echo "$POST_INSTALL" | grep -e . | while read -r check; do
      if ! ( echo "$check" | docker run --rm -i "$dockertag" ); then
        echo "$check"
        echo "❌ Failed for $INTEGRATION:$distro-$TAG"
        return 10
      fi
    done
    echo "✅ Post-installation checks for $dockertag succeeded"
    return 0
}

for distro in centos debian suse; do
    echo "ℹ️ Building base image for $distro..."
    docker build -t "$distro-base" -f "$GITHUB_ACTION_PATH/dockerfiles-base/Dockerfile-base-$distro" .

    echo "ℹ️ Testing clean install"
    build_and_test false
    (( errors += $? ))

    if [[ "$UPGRADE" = "true" ]]; then
        echo "ℹ️ Testing upgrade path"
        build_and_test true
        (( errors += $? ))
    else
        echo "ℹ️ Skipping upgrade path"
    fi
done

exit $errors
