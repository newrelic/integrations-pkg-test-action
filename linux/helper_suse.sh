# Adds the NR repo
add_repo() {
    env=""
    domain="nr-downloads-main.s3-website-us-east-1.amazonaws.com"
    if [ "$STAGING_REPO" = "true" ]; then
        env="-staging"
        domain="nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com"
    fi

    # os-release file should have this structure:
    #   NAME="SLES"
    #   VERSION="15-SP3"
    #   VERSION_ID="15.3"
    #   PRETTY_NAME="SUSE Linux Enterprise Server 15 SP3"
    #   ID="sles"
    #   ID_LIKE="suse"
    #   ANSI_COLOR="0;32"
    #   CPE_NAME="cpe:/o:suse:sles:15:sp3"
    #   DOCUMENTATION_URL="https://documentation.suse.com/"
    . /etc/os-release
    printf "Detected version '%s' from os-release" "$VERSION_ID"

    if [ "${VERSION_ID%%.*}" -eq 12 ]; then
        cp suse-12-oss.repo /etc/zypp/repos.d/suse-12-oss.repo
        cp suse-12-non-oss.repo /etc/zypp/repos.d/suse-12-non-oss.repo
        zypper --gpg-auto-import-keys ref
    fi

    zypper -n install wget
    wget -q "http://${domain}/infrastructure_agent/gpg/newrelic-infra.gpg" -O newrelic-infra.gpg
    rpm --import newrelic-infra.gpg && rm newrelic-infra.gpg

    zypper -n addrepo "http://${domain}/infrastructure_agent/linux/zypp/sles/${VERSION_ID}/x86_64/newrelic-infra.repo"
    zypper --gpg-auto-import-keys ref
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
