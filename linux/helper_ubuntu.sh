# Adds the NR repo
add_repo() {
    # Extract :version from DISTRO tag
    version=${BASE_IMAGE##*:}
    if [ -z "$version" ]; then
        printf "Cannot figure out version from BASE_IMAGE %s" "$BASE_IMAGE"
        return 1
    fi

    apt update && apt -y install wget gnupg
    if [ "$STAGING_REPO" = "true" ]; then
        echo "staginRepo is true"
        if [ "$DEST_PREFIX" -ne "infrastructure_agent/"]; then
            echo "destPrefix is not infrastructure_agent/ it is $DEST_PREFIX"
            repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/${DEST_PREFIX}linux/apt"
        else
            echo "destPrefix is $DEST_PREFIX"
            repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/apt"
        fi
    else
        echo "staginRepo is false"
        repo="http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/apt"
    fi

    echo "deb [arch=amd64] $repo $version main" > /etc/apt/sources.list.d/newrelic-infra.list
    wget -nv -O- http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/infrastructure_agent/gpg/newrelic-infra.gpg | apt-key add -
    apt update
}


install_agent() {
    # TODO: Use the repo version when the staging repo gets fixed, since the systemd issue is workarounded
    # apt install -y newrelic-infra

    AGENT_PACKAGE=${AGENT_PACKAGE:-newrelic-infra_systemd_1.15.2_systemd_amd64.deb}
    wget -nv "http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/apt/pool/main/n/newrelic-infra/${AGENT_PACKAGE}"
    apt install "./${AGENT_PACKAGE}"
}

# Install package from local file
install_local() {
    apt install -y "./dist/${INTEGRATION}_${TAG}-1_amd64.deb"
}

# Install package from repository
install_repo() {
    version=""
    if [ "$REPO_VERSION" != "" ]; then
        version="=$REPO_VERSION"
    fi
    apt install -y "${INTEGRATION}${version}"
}
