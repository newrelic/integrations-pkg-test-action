#!/usr/bin/env sh

# helper.sh runs inside the docker container and takes care of adding repos, packages, and performing checks

set -e

# Return the helper script to be used for the specified docker docker_image
helper_name() {
    case $1 in
    ubuntu:* | debian:*)
        printf "ubuntu"
        ;;
    rockylinux:*)
        printf "rockylinux"
        ;;
    registry.suse.com/suse/sle*)
        printf "suse"
        ;;
    esac
}

if [ -z "$BASE_IMAGE" ]; then
    echo "BASE_IMAGE env var not defined, exiting"
    exit 1
fi

# Get helper suffix from the docker tag.
# E.g. from `ubuntu:focal`, get `ubuntu`.
helper=$(helper_name "$BASE_IMAGE")
if [ -z "$helper" ]; then
    echo "❌ Could not find a helper script for distro $BASE_IMAGE"
    exit 1
fi

# Distro-specific scripts define add_repo, install_agent, install_local and install_repo functions
# shellcheck source=helper_ubuntu.sh
. "./helper_${helper}.sh"

# Prepare step: Add NR repo and dependencies
if [ "$1" = "prepare" ]; then
    if ! add_repo; then
        echo "❌ Could not add NR repo to the image"
        exit 1
    fi

    # Make a dummy systemctl so post-install script does not fail
    test ! -e /bin/systemctl || mv /bin/systemctl /bin/systemctl.bak
    ln -s /bin/true /bin/systemctl

    if ! install_agent; then
        echo "❌ Could not install agent package"
        exit 2
    fi
elif [ "$1" = "install" ]; then
    if [ "${INSTALL_REPO}" = "true" ]; then
        if ! install_repo; then
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
