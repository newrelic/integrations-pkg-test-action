#!/bin/bash

set -o errexit
set -o pipefail

# Populate defaults
[[ -n $GITHUB_ACTION_PATH ]] || GITHUB_ACTION_PATH=$(pwd)
[[ -n $DISTROS ]] || DISTROS="centos suse ubuntu"
[[ -n $PKGDIR ]] || PKGDIR="./dist"

if [[ -z $POST_INSTALL ]]; then
    POST_INSTALL="
    test -e /etc/newrelic-infra/integrations.d/${INTEGRATION/nri-/}-config.yml.sample
    test -e /var/db/newrelic-infra/newrelic-integrations/${INTEGRATION/nri-/}-definition.yml
    test -e /usr/share/doc/${INTEGRATION}/LICENSE*
    test -e /usr/share/doc/${INTEGRATION}/CHANGELOG*
    test -e /usr/share/doc/${INTEGRATION}/README*
    test -x /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION}
    /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION} -show_version 2>&1 | grep -e $TAG
    "
fi
POST_INSTALL="$POST_INSTALL
$POST_INSTALL_EXTRA"

# Strip leading v from TAG if present
TAG=${TAG/v/}

function build_and_test() {
    if [[ $1 = "true" ]]; then upgradesuffix="-upgrade"; fi
    dockertag="$INTEGRATION:$distro-$TAG$upgradesuffix"

    echo "ℹ️ Running installation test for $dockertag"
    if ! docker build -t "$dockertag" -f "$GITHUB_ACTION_PATH/dockerfiles-test/Dockerfile-$distro"\
      --build-arg TAG="$TAG"\
      --build-arg INTEGRATION="$INTEGRATION"\
      --build-arg UPGRADE="$1"\
      --build-arg PKGDIR="$PKGDIR"\
    .; then
        echo "❌ Install for $dockertag failed"
        return 1
    fi
    echo "✅ Installation for $dockertag succeeded"

    echo "ℹ️ Running post-installation checks for $dockertag"
    echo "$POST_INSTALL" | while read -r check; do
        [[ -n $check ]] || continue
        if ! ( echo "$check" | docker run --rm -i "$dockertag" ); then
            echo "  ❌ $check"
            return 2
        fi
        echo "  ✅ $check"
    done
    echo "✅ Post-installation checks for $dockertag succeeded"
    return 0
}

echo "$DISTROS" | tr " " "\n" | while read -r distro; do
    echo "::group::Build base image for $distro"
    docker build -t "$distro-base" -f "$GITHUB_ACTION_PATH/dockerfiles-base/Dockerfile-base-$distro" .
    echo "::endgroup::"

    echo "::group::Clean install on $distro"
    build_and_test false
    echo "::endgroup::"

    if [[ "$UPGRADE" = "true" ]]; then
        echo "::group::Upgrade path on $distro"
        build_and_test true
        echo "::endgroup::"
    else
        echo "ℹ️ Skipping upgrade path on $distro"
    fi
done
