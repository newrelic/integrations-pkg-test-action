#!/bin/bash
n=0

docker build -f $GITHUB_ACTION_PATH/dockerfiles-test/Dockerfile-suse    --build-arg TAG="${TAG}" --build-arg INTEGRATION="${INTEGRATION}" --build-arg TEST_EXISTENCE="${TEST_EXISTENCE}" .
if [[ $? -ne 0 ]] ; then
    echo "suse tests failed"
    ((n+=1))
fi

docker build -f $GITHUB_ACTION_PATH/dockerfiles-test/Dockerfile-suse    --build-arg TAG="${TAG}" --build-arg INTEGRATION="${INTEGRATION}" --build-arg TEST_EXISTENCE="${TEST_EXISTENCE}" --build-arg TEST_UPDATE=true .
if [[ $? -ne 0 ]] ; then
    echo "suse update tests failed"
    ((n+=1))
fi

docker build -f $GITHUB_ACTION_PATH/dockerfiles-test/Dockerfile-centos  --build-arg TAG="${TAG}" --build-arg INTEGRATION="${INTEGRATION}" --build-arg TEST_EXISTENCE="${TEST_EXISTENCE}" .
if [[ $? -ne 0 ]] ; then
    echo "centos tests failed"
    ((n+=1))
fi

docker build -f $GITHUB_ACTION_PATH/dockerfiles-test/Dockerfile-centos  --build-arg TAG="${TAG}" --build-arg INTEGRATION="${INTEGRATION}" --build-arg TEST_EXISTENCE="${TEST_EXISTENCE}" --build-arg TEST_UPDATE=true .
if [[ $? -ne 0 ]] ; then
    echo "centos update tests failed"
    ((n+=1))
fi

docker build -f $GITHUB_ACTION_PATH/dockerfiles-test/Dockerfile-debian  --build-arg TAG="${TAG}" --build-arg INTEGRATION="${INTEGRATION}" --build-arg TEST_EXISTENCE="${TEST_EXISTENCE}" .
if [[ $? -ne 0 ]] ; then
    echo "debian tests failed"
    ((n+=1))
fi

docker build -f $GITHUB_ACTION_PATH/dockerfiles-test/Dockerfile-debian  --build-arg TAG="${TAG}" --build-arg INTEGRATION="${INTEGRATION}" --build-arg TEST_EXISTENCE="${TEST_EXISTENCE}" --build-arg TEST_UPDATE=true .
if [[ $? -ne 0 ]] ; then
    echo "debian update tests failed"
    ((n+=1))
fi

if [ $n -gt 0 ];
then
    echo $n "tests failed"
    exit 1
fi