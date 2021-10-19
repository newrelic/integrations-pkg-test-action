# Adds the NR repo
add_repo() {
    env=""
    if [ "$STAGING_REPO" = "true" ]; then
        env="-staging"
    fi
    cp "newrelic-infra-suse${env}.repo" /etc/zypp/repos.d/newrelic-infra.repo

    # Extract version and SP from docker image
    version=$(echo "$BASE_IMAGE" | grep -oE 'sles?[0-9]+' | grep -oE '[0-9]+')
    if [ -z "$version" ]; then
        printf "Unable to parse Suse version from BASE_IMAGE tag '%s'" "$BASE_IMAGE"
        return 1
    fi

    # Versions earlier than 15 are deprecated and their repos are down. E.g. installing wget is not possible.
    if [ "$version" -lt 15 ]; then
        echo "Only Suse versions 15 and higher are supported by this action"
        return 2
    fi

    sp=$(echo "$BASE_IMAGE" | grep -oE 'sp[0-9]+' | grep -oE '[0-9]+')
    if [ -n "$sp" ]; then
        version="${version}.${sp}"
    fi

    printf "Detected version '%s' from docker tag" "$version"

    sed -i "s/__VERSION__/$version/" /etc/yum.repos.d/newrelic-infra.repo

    zypper -n install wget gnupg
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
