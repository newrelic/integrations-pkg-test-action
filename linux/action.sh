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
    test -x /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION}
    /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION} -show_version 2>&1 | grep -e $TAG
    "
fi
POST_INSTALL="$POST_INSTALL
$POST_INSTALL_EXTRA"

# Returns the docker image for the specified distro ($1)
function image_for() {
    case $1 in
    "ubuntu")
        printf "ubuntu:focal"
        ;;
    "suse")
        printf "opensuse/leap"
        ;;
    "centos")
        printf "centos:centos8"
        ;;
    esac
}

function build_and_test() {
    upgrade=$1

    # Decide whether to install locally, from repo, or both based on action inputs
    if [[ "$PACKAGE_LOCATION" == "local" ]]; then
        # Always install local package if location is local
        install_local=true
        # Install repo package if this is an upgrade test
        install_repo=$upgrade
        # We're testing locally so we allow failures installing from the repo
        fail_repo=false
    elif [[ "$PACKAGE_LOCATION" == "repo" ]]; then
        if [[ "$upgrade" == "true" ]]; then
            # Remote package and upgrade, invalid case
            echo "❌ Cannot run upgrade test on when PACKAGE_LOCATION=repo, skipping"
            return 1
        fi
        # Repo package, not upgrade, install repo only
        install_repo=true
        install_local=false
        fail_repo=true
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

    # Get base image from distro
    base_image=$(image_for "$distro")
    if [[ -z "$base_image" ]]; then
        echo "❌ Internal error: cannot figure base docker image for '$distro'"
        return 1
    fi

    # Docker needs to copy both user-supplied items (packages) and action-supplied items (helper*.sh scripts)
    # Since build context is tied to the WD for `docker run`, we need to create a temp dir and copy both things there
    dockerdir=$(mktemp -d || true)
    if [[ -z "$dockerdir" ]]; then
        echo "❌ Internal error: could not create temp dir with mktemp"
        return 1
    fi
    echo "ℹ️ Copying helper scripts to $dockerdir"
    mkdir "${dockerdir}/dist"
    cp "$GITHUB_ACTION_PATH"/helper*.sh "$dockerdir" # Copy helpers
    cp -r "$GITHUB_ACTION_PATH"/rpm-repos "$dockerdir" # Copy .repo files for rpm-based distros
    # If we want to install local packages, copy them as well
    if [[ "$install_local" == "true" ]]; then
        echo "ℹ️ Copying packages from $PKGDIR to $dockerdir"
        find "$PKGDIR" -type f -maxdepth 1 | while read -r package; do
            if ! cp "$package" "${dockerdir}/dist/"; then
                echo "❌ Internal error: could not copy packages from PKGDIR=${PKGDIR} to ${dockerdir}/dist"
                return 1
            fi
        done
    fi

    echo "ℹ️ Running installation test for $dockertag"
    echo "::group::docker build $dockertag"
    if ! docker build -t "$dockertag" -f "${GITHUB_ACTION_PATH}/Dockerfile" \
        --build-arg DISTRO="$distro" \
        --build-arg BASE_IMAGE="$base_image" \
        --build-arg TAG="$TAG" \
        --build-arg INTEGRATION="$INTEGRATION" \
        --build-arg INSTALL_REPO="$install_repo" \
        --build-arg INSTALL_LOCAL="$install_local" \
        --build-arg FAIL_REPO="$fail_repo" \
        --build-arg STAGING_REPO="$STAGING_REPO" \
        "$dockerdir"; then
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
