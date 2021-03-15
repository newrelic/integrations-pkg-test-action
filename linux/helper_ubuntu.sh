# Adds the NR repo
add_repo() {
    apt update && apt -y install wget gnupg
    if [ "$STAGING_REPO" = "true" ]; then
        repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/apt";
    else
        repo="https://download.newrelic.com/infrastructure_agent/linux/apt";
    fi

    echo "deb [arch=amd64] $repo focal main" > /etc/apt/sources.list.d/newrelic-infra.list

    wget https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg -O - | apt-key add -
    apt update
}

# Installs the agent package without the systemd dependency
# This is needed because systemd is not available in the docker images, so the post-install script of
# the normal package would fail
install_agent() {
    AGENT_PACKAGE=${AGENT_PACKAGE:-newrelic-infra_upstart_1.15.2_upstart_amd64.deb}
    wget "https://download.newrelic.com/infrastructure_agent/linux/apt/pool/main/n/newrelic-infra/${AGENT_PACKAGE}"
    apt install "./${AGENT_PACKAGE}"
}

# Install package from local file
install_local() {
    apt install -y "./dist/${INTEGRATION}_${TAG}-1_amd64.deb"
}

# Install package from repository
install_repo() {
    apt install -y ${INTEGRATION}
}
