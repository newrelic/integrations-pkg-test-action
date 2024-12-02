# Adds the NR repo
add_repo() {
    env=""
    if [ "$STAGING_REPO" = "true" ]; then
        env="-staging"
    fi
    cp "newrelic-infra-rockylinux${env}.repo" /etc/yum.repos.d/newrelic-infra.repo

    if [ "$STAGING_REPO" = "true" ]; then 
        if [ "$DEST_PREFIX" != "infrastructure_agent/"]; then
            sed -i "s|baseurl=http://nr-downloads-ohai-staging\.s3-website-us-east-1\.amazonaws\.com/infrastructure_agent/linux/yum/el/__VERSION__/x86_64|baseurl=http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/${DEST_PREFIX}linux/yum/el/__VERSION__/x86_64|" /etc/yum.repos.d/newrelic-infra.repo
            sed -i "s|gpgkey=http://nr-downloads-ohai-staging\.s3-website-us-east-1\.amazonaws\.com/infrastructure_agent/gpg/newrelic-infra\.gpg|gpgkey=http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/${DEST_PREFIX}gpg/newrelic-infra.gpg|" /etc/yum.repos.d/newrelic-infra.repo
        fi
    else
        if [ "$DEST_PREFIX" != "infrastructure_agent/"]; then
            sed -i "s|baseurl=http://nr-downloads-main\.s3-website-us-east-1\.amazonaws\.com/infrastructure_agent/linux/yum/el/__VERSION__/x86_64|baseurl=http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/${DEST_PREFIX}linux/yum/el/__VERSION__/x86_64|" /etc/yum.repos.d/newrelic-infra.repo
            sed -i "s|gpgkey=http://nr-downloads-main\.s3-website-us-east-1\.amazonaws\.com/infrastructure_agent/gpg/newrelic-infra.gpg|gpgkey=http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/${DEST_PREFIX}gpg/newrelic-infra.gpg|" /etc/yum.repos.d/newrelic-infra.repo
        fi
    fi

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
    version=""
    if [ "$REPO_VERSION" != "" ]; then
        version="-$REPO_VERSION"
    fi
    yum -y install "${INTEGRATION}${version}"
}
