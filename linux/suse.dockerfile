FROM opensuse/leap as suse-base

ARG STAGING_REPO=false

# Installing needed tools
RUN zypper -n install wget gnupg curl

RUN if [ "${STAGING_REPO}" = "true" ]; then \
        repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/zypp/sles/12.4/x86_64/newrelic-infra.repo"; \
    else \
        repo="https://download.newrelic.com/infrastructure_agent/linux/zypp/sles/12.4/x86_64/newrelic-infra.repo"; \
    fi; \
    curl -o /etc/zypp/repos.d/newrelic-infra.repo $repo

# Adding Newrelic repository
RUN curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg -s |  gpg --import && \
    zypper --gpg-auto-import-keys ref && \
    zypper -n ref -r newrelic-infra && \
    zypper -n install newrelic-infra


FROM suse-base

ARG INTEGRATION
ARG TAG
ARG PKGDIR=./dist
ARG INSTALL_REPO=false
ARG FAIL_REPO=false
ARG INSTALL_LOCAL=true

ADD ${PKGDIR} ./dist

# Complex stuff below: When installing from the repo, if installation fails, check if we're also installing locally.
# If this is the case, we don't really care (package is new and not in the repos) so we print a warning and exit.
# If we're not installing locally, the third or-ed expression triggers and we exit with an error.
# Also, complex flow needs to be preceded by "set -e" to exit on error
RUN set -e && \
    if [ "${INSTALL_REPO}" = "true" ]; then \
        zypper -n install ${INTEGRATION} || ( [ "${FAIL_REPO}" = "failse" ] && echo "⚠️ Previous version install failed, proceeding anyway" ); \
    fi; \
    if [ "${INSTALL_LOCAL}" = "true" ]; then \
        zypper -n install "./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm"; \
    fi
