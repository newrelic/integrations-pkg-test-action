# Adds the NR repo
add_repo() {
    if [ "$STAGING_REPO" = "true" ]; then
        repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/zypp/sles/12.4/x86_64/newrelic-infra.repo"
    else
        repo="https://download.newrelic.com/infrastructure_agent/linux/zypp/sles/12.4/x86_64/newrelic-infra.repo"
    fi

    zypper -n install wget gnupg curl
    curl -o /etc/zypp/repos.d/newrelic-infra.repo $repo
    curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg -s |  gpg --import
    zypper --gpg-auto-import-keys ref
    zypper -n ref -r newrelic-infra
}

install_agent() {
    ln -s /bin/true /bin/systemctl || true # Dummy systemctl so post-install script does not fail
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
