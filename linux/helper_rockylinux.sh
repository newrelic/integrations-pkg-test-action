# Adds the NR repo
add_repo() {
    env=""
    if [ "$STAGING_REPO" = "true" ]; then
        env="-staging"
    fi
    cp "newrelic-infra-rockylinux${env}.repo" /etc/yum.repos.d/newrelic-infra.repo

    # Get rockylinux version from docker tag, assuming it has a `:[0-9]` format
    version=${BASE_IMAGE##*:}
    sed -i -e "s/__VERSION__/$version/" -e "s#__PREFIX__#${REPO_PREFIX:-infrastructure_agent}#g" /etc/yum.repos.d/newrelic-infra.repo

    # A custom prefix only holds the published integrations: the agent they depend on comes from the default repo
    if [ "${REPO_PREFIX:-infrastructure_agent}" != "infrastructure_agent" ]; then
        sed -e "s/__VERSION__/$version/" -e "s#__PREFIX__#infrastructure_agent#g" -e "s/^\[newrelic-infra\]/[newrelic-infra-agent]/" \
            "newrelic-infra-rockylinux.repo" > /etc/yum.repos.d/newrelic-infra-agent.repo
        echo "includepkgs=newrelic-infra" >> /etc/yum.repos.d/newrelic-infra-agent.repo
    fi

    dnf clean all && rm -r /var/cache/dnf  && dnf upgrade -y && dnf update -y
    yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra*'
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
    version=""
    if [ "$REPO_VERSION" != "" ]; then
        version="-$REPO_VERSION"
    fi
    yum -y install "${INTEGRATION}${version}"
}
