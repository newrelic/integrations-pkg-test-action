# Adds the NR repo
add_repo() {
    zypper -n install wget gnupg

    env=""
    if [ "$STAGING_REPO" = "true" ]; then
        env="-staging"
    fi
    cp "newrelic-infra-suse${env}.repo" /etc/zypp/repos.d/newrelic-infra.repo

    # Extract version and SP from docker image
    version=$(echo "$BASE_IMAGE" | grep -oE 'sles?[0-9]+' | grep -oE '[0-9]+')
    sp=$(echo "$BASE_IMAGE" | grep -oE 'sp[0-9]+' | grep -oE '[0-9]+')
    if [ -n "$sp" ]; then
        version="${version}.${sp}"
    fi

    sed -i "s/__VERSION__/$version/" /etc/yum.repos.d/newrelic-infra.repo

    wget -nv -O- http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/infrastructure_agent/gpg/newrelic-infra.gpg |  gpg --import
    zypper --gpg-auto-import-keys ref
    zypper -n ref -r newrelic-infra
}

install_agent() {
    zypper -n install newrelic-infra
}

# Install package from local file
install_local() {
    zypper -n install "./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm"
}

# Install package from repository
install_repo() {
    zypper -n install "$INTEGRATION"
}
