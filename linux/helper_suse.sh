# Adds the NR repo
add_repo() {
    if [ "$STAGING_REPO" = "true" ]; then
        repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/zypp/sles/12.4/x86_64/newrelic-infra.repo"
    else
        repo="http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/zypp/sles/12.4/x86_64/newrelic-infra.repo"
    fi

    zypper -n install wget gnupg
    wget -nv -O /etc/zypp/repos.d/newrelic-infra.repo $repo
    # prod .repo file points to the cache url, we replace it to point to the bucket url
    rs='s|https://download.newrelic.com|http://nr-downloads-main.s3-website-us-east-1.amazonaws.com|'
    sed -i "$rs" /etc/zypp/repos.d/newrelic-infra.repo

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
