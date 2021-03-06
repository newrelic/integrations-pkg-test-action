# Adds the NR repo
add_repo() {
    env=""
    if [ "$STAGING_REPO" = "true" ]; then
        env="-staging"
    fi
    cp "newrelic-infra-centos${env}.repo" /etc/yum.repos.d/newrelic-infra.repo
    yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
    yum update -y
}

install_agent() {
    yum -y install newrelic-infra
}

# Install package from local file
install_local() {
    yum -y install "./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm"
}

# Install package from repository
install_repo() {
    yum -y install "$INTEGRATION"
}
