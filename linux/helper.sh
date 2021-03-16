#!/usr/bin/env sh

# helper.sh runs inside the docker image and takes care of adding repos, packages, and performing checks

set -e

if [ -z "$DISTRO" ]; then
    echo "DISTRO env var not defined, exiting"
    exit 1
fi

# Distro-specific scripts define add_repo, install_agent, install_local and install_repo functions
# shellcheck source=helper_ubuntu.sh
. "./helper_${DISTRO}.sh"

# Prepare step: Add NR repo and dependencies
if [ "$1" = "prepare" ]; then
    if ! add_repo; then
        echo "❌ Could not add NR repo to the image"
        exit 1
    fi

    # Make a dummy systemctl so post-install script does not fail
    test -e /usr/local/bin/systemctl || ln -s /bin/true /usr/local/bin/systemctl

    if ! install_agent; then
        echo "❌ Could not install agent package"
        exit 2
    fi
elif [ "$1" = "install" ]; then
    if [ "${INSTALL_REPO}" = "true" ]; then
        if ! install_repo; then
            echo "FAIL_REPO=${FAIL_REPO}"
            if [ "${FAIL_REPO}" = "true" ]; then
                echo "❌ Error installing $INTEGRATION from repo"
                exit 3
            else
                echo "⚠️ Error installing $INTEGRATION from repo, proceeding anyway"
            fi
        fi
    fi

    if [ "${INSTALL_LOCAL}" = "true" ]; then
        if ! install_local; then
            echo "❌ Error installing $INTEGRATION from upstream"
            exit 4
        fi
    fi
fi
