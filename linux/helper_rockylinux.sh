# Adds the NR repo
add_repo() {
    env=""
    if [ "$STAGING_REPO" = "true" ]; then
        env="-staging"
    fi
    cp "newrelic-infra-rockylinux${env}.repo" /etc/yum.repos.d/newrelic-infra.repo

    # Get rockylinux version from docker tag, assuming it has a `:[0-9]` format
    version=${BASE_IMAGE##*:}
    sed -i "s/__VERSION__/$version/" /etc/yum.repos.d/newrelic-infra.repo

    dnf clean all && rm -r /var/cache/dnf  && dnf upgrade -y && dnf update -y
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
