# Adds the NR repo
add_repo() {
    # Extract :version from DISTRO tag
    version=${BASE_IMAGE##*:}
    if [ -z "$version" ]; then
        printf "Cannot figure out version from BASE_IMAGE %s" "$BASE_IMAGE"
        return 1
    fi

    prefix=${REPO_PREFIX:-infrastructure_agent}
    apt update && apt -y install wget gnupg
    if [ "$STAGING_REPO" = "true" ]; then
        repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/${prefix}/linux/apt"
    else
        repo="http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/${prefix}/linux/apt"
    fi

    mkdir -p /etc/apt/keyrings
    wget -nv -O- "http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/infrastructure_agent/gpg/newrelic-infra-sha256.gpg" | gpg --dearmor -o /etc/apt/keyrings/newrelic-infra.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/newrelic-infra.gpg] $repo $version main" > /etc/apt/sources.list.d/newrelic-infra.list
    # A custom prefix only holds the published integrations: the agent they depend on comes from the default repo
    if [ "$prefix" != "infrastructure_agent" ]; then
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/newrelic-infra.gpg] http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/apt $version main" > /etc/apt/sources.list.d/newrelic-infra-agent.list
    fi
    apt update
}


install_agent() {
    # TODO: Use the repo version when the staging repo gets fixed, since the systemd issue is workarounded
    # apt install -y newrelic-infra

    AGENT_PACKAGE=${AGENT_PACKAGE:-newrelic-infra_systemd_2.0.1_amd64.deb}
    wget -nv "http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/apt/pool/main/n/newrelic-infra/${AGENT_PACKAGE}"
    apt install -y "./${AGENT_PACKAGE}"
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
