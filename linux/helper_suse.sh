# Adds the NR repo
add_repo() {
    env=""
    domain="download.newrelic.com"
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
    major_version="$(echo -n "$VERSION_ID" | cut -d. -f1)"
    printf "Detected version '%s' from os-release" "$VERSION_ID"

    if [ "$major_version" -eq 15 ]; then
        zypper -n install wget
        wget -qO- "http://${domain}/infrastructure_agent/gpg/newrelic-infra.gpg" | gpg --import
        zypper -n addrepo "http://${domain}/infrastructure_agent/linux/zypp/sles/${VERSION_ID}/x86_64/newrelic-infra.repo"
        zypper --gpg-auto-import-keys ref
    elif [ "$major_version" -eq 12 ]; then
        sed -e "s/__VERSION__/${VERSION_ID}/g" "newrelic-infra-suse-12${env}.repo" > /etc/zypp/repos.d/newrelic-infra.repo
        zypper -n ref -r newrelic-infra
    else
        echo "Only Suse versions 12 and 15 are supported by this action"
        return 1
    fi
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
