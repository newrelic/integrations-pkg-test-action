# Adds the NR repo
add_repo() {
    domain="nr-downloads-main.s3-website-us-east-1.amazonaws.com"
    env=""
    if [ "$STAGING_REPO" = "true" ]; then
        domain="nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com"
        env="-staging"
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

    cp "newrelic-infra-suse${env}.repo" tmp.repo
    sed -e "s/__VERSION__/$VERSION_ID/g" tmp.repo > /etc/zypp/repos.d/newrelic-infra.repo
    if [ "$STAGING_REPO" = "true" ]; then 
        if [ "$DEST_PREFIX" != "infrastructure_agent/"]; then
            sed -i "s|baseurl=http://nr-downloads-ohai-staging\.s3-website-us-east-1\.amazonaws\.com/infrastructure_agent/linux/zypp/sles/__VERSION__/x86_64|baseurl=http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/${DEST_PREFIX}linux/zypp/sles/__VERSION__/x86_64|" /etc/zypp/repos.d/newrelic-infra.repo
            # sed -i "s|gpgkey=http://download\.newrelic\.com/infrastructure_agent/gpg/newrelic-infra\.gpg|gpgkey=http://download.newrelic.com/${DEST_PREFIX}gpg/newrelic-infra.gpg|" /etc/zypp/repos.d/newrelic-infra.repo 
        fi
    else
        if [ "$DEST_PREFIX" != "infrastructure_agent/"]; then
            sed -i "s|baseurl=http://nr-downloads-main\.s3-website-us-east-1\.amazonaws\.com/infrastructure_agent/linux/zypp/sles/__VERSION__/x86_64|baseurl=http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/${DEST_PREFIX}linux/zypp/sles/__VERSION__/x86_64|" /etc/zypp/repos.d/newrelic-infra.repo
            # sed -i "s|gpgkey=http://nr-downloads-main\.s3-website-us-east-1\.amazonaws\.com/infrastructure_agent/gpg/newrelic-infra.gpg|gpgkey=http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/${DEST_PREFIX}gpg/newrelic-infra.gpg|" /etc/zypp/repos.d/newrelic-infra.repo
        fi
    fi
    zypper --gpg-auto-import-keys ref
}

install_agent() {
    zypper -n install newrelic-infra
}

# Install package from local file
install_local() {
    . /etc/os-release
    if [ "${VERSION_ID%%.*}" -eq 12 ]; then
        # Workaround Zypper failing to check signature of rpm for certain packages.
        # TODO: coulnd't find the exact reason why but nri-nginx packages starting from 3.2.1 started
        # to fail signature check with zypper. 
        rpm -qpi "./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm" |grep "^Signature.*bb29ee038ecce87c$"
        rpm --checksig "./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm"

        zypper -n --no-gpg-checks install "./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm" 
        return
    fi

    zypper -n install "./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm" 
}

# Install package from repository
install_repo() {
    version=""
    if [ "$REPO_VERSION" != "" ]; then
        version="=$REPO_VERSION"
    fi
    zypper -n install "${INTEGRATION}${version}"
}
