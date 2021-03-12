#!/usr/bin/env bash

set -o errexit
set -o pipefail

# Populate defaults
[[ -n $GITHUB_ACTION_PATH ]] || GITHUB_ACTION_PATH=$(pwd)
[[ -n $DISTROS ]] || DISTROS="centos suse ubuntu"
[[ -n $PKGDIR ]] || PKGDIR="./dist"
[[ -n $PACKAGE_LOCATION ]] || PACKAGE_LOCATION="local"

# Strip leading v from TAG if present
TAG=${TAG/v/}

# Default post-install test suite
if [[ -z $POST_INSTALL ]]; then
    POST_INSTALL="
    test -e /etc/newrelic-infra/integrations.d/${INTEGRATION/nri-/}-config.yml.sample
    test -e /var/db/newrelic-infra/newrelic-integrations/${INTEGRATION/nri-/}-definition.yml
    test -x /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION}
    /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION} -show_version 2>&1 | grep -e $TAG
    "
fi
POST_INSTALL="$POST_INSTALL
$POST_INSTALL_EXTRA"

function build_and_test() {
    upgrade=$1
    if [[ "$PACKAGE_LOCATION" == "local" ]]; then
        # Always install local package if location is local
        install_local=true
        # Install repo package if this is an upgrade test
        install_repo=$upgrade
    elif [[ "$PACKAGE_LOCATION" == "repo" ]]; then
        if [[ "$upgrade" == "true" ]]; then
            # Remote package and upgrade, invalid case
            echo "❌ Cannot run upgrade test on when PACKAGE_LOCATION=repo, skipping"
            return 1
        fi
        # Repo package, not upgrade, install repo only
        install_repo=true
        install_local=false
    else
        echo "❌ Unknown value for PACKAGE_LOCATION '${PACKAGE_LOCATION}'"
        return 1
    fi

    # Compute suffix for the docker tag
    suffix=""
    if [[ "$install_repo" == "true" ]]; then suffix=${suffix}-repo; fi
    if [[ "$STAGING_REPO" == "true" ]]; then suffix=${suffix}-staging; fi
    if [[ "$install_local" == "true" ]]; then suffix=${suffix}-local; fi

    dockertag="${INTEGRATION}:${distro}-${TAG}${suffix}"

    echo "ℹ️ Running installation test for $dockertag"
    echo "::group::docker build $dockertag"
    if ! docker build -t "$dockertag" -f "${GITHUB_ACTION_PATH}/${distro}.dockerfile" \
        --build-arg TAG="$TAG" \
        --build-arg INTEGRATION="$INTEGRATION" \
        --build-arg INSTALL_REPO="$install_repo" \
        --build-arg INSTALL_LOCAL="$install_local" \
        --build-arg PKGDIR="$PKGDIR" \
        --build-arg STAGING_REPO="$STAGING_REPO" \
        .; then
        echo "::endgroup::"
        echo "❌ Install for $dockertag failed"
        return 1
    fi
    echo "::endgroup::"
    echo "✅ Installation for $dockertag succeeded"

    echo "ℹ️ Running post-installation checks for $dockertag"
    if ! echo "$POST_INSTALL" | {
        # This is just a while | read construct with a local variable to store failures
        failed=0
        while read -r check; do
            [[ -n $check ]] || continue # Skip empty lines
            # Feed each check to a fresh instance of the docker container
            if ! (echo "$check" | docker run --rm -i "$dockertag"); then
                echo "  ❌ $check"
                failed=1
                continue
            fi
            echo "  ✅ $check"
        done
        return $failed
    }; then
        echo "❌ Post-installation checks for $dockertag failed"
        return 1
    fi

    echo "✅ Post-installation checks for $dockertag succeeded"
    return 0
}

echo "$DISTROS" | tr " " "\n" | while read -r distro; do
    build_and_test false

    if [[ "$UPGRADE" == "true" ]]; then
        build_and_test true
    else
        echo "ℹ️ Skipping upgrade path on $distro"
    fi
done
