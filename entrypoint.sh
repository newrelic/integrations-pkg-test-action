#!/usr/bin/env bash
set -eo

errors=0

if [[ -z $POST_INSTALL ]]; then
    POST_INSTALL="
    test -e /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION}
    /var/db/newrelic-infra/newrelic-integrations/bin/${INTEGRATION} -show_version | grep -e "$TAG"
    "
fi

function build_and_test() {
    if ! docker build -t "$INTEGRATION:$distro-$TAG" -f $GITHUB_ACTION_PATH/dockerfiles-test/Dockerfile-$distro --build-arg TAG="${TAG}" --build-arg INTEGRATION="${INTEGRATION}" --build-arg UPGRADE=$1 .; then
        echo "Clean install failed on $distro" 1>&2
        return 1
    fi
    echo "Installation succeeded install done"

    echo "Running post-installation checks"
    echo "$POST_INSTALL" | while read check; do
      if ! echo "$check" | docker run --rm -i $INTEGRATION:$distro-$TAG; then
        echo "$check"
        echo Failed for $INTEGRATION:$distro-$TAG
        return 1
      fi
    done
}

for distro in centos debian suse; do
    echo "Building base image for $distro..."
    docker build -t "$distro-test" -f $GITHUB_ACTION_PATH/dockerfiles-base/Dockerfile-base-$distro .

    echo "Testing clean install"
    build_and_test false
    ((errors += $? ))

    if [[ $UPGRADE == "true" ]]; then
        echo "Testing upgrade path"
        build_and_test true
        ((errors += $? ))
    else
        echo "Skipping upgrade path"
    fi
done

exit $errors
