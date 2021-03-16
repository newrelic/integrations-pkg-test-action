# Adds the NR repo
add_repo() {
    yum update -y
    yum install -y wget

    if [ "$STAGING_REPO" = "true" ]; then
        repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/yum/el/8/x86_64/newrelic-infra.repo"
    else
        repo="https://download.newrelic.com/infrastructure_agent/linux/yum/el/8/x86_64/newrelic-infra.repo"
    fi

    wget -nv -O /etc/yum.repos.d/newrelic-infra.repo "$repo"
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
