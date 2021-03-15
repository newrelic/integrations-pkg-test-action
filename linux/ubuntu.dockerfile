FROM ubuntu:focal as ubuntu-base

ARG STAGING_REPO=false

# Installing needed tools
RUN apt update && \
    apt -y install wget gnupg

# Install agent manually, since the one pulled from the repo will try to spin up a systemd service and fail
ARG AGENT_PACKAGE=newrelic-infra_upstart_1.15.2_upstart_amd64.deb
RUN wget https://download.newrelic.com/infrastructure_agent/linux/apt/pool/main/n/newrelic-infra/${AGENT_PACKAGE} && \
    apt install ./${AGENT_PACKAGE}

# Adding Newrelic repository
RUN if [ "${STAGING_REPO}" = "true" ]; then \
        repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/apt"; \
    else \
        repo="https://download.newrelic.com/infrastructure_agent/linux/apt"; \
    fi; \
    echo "deb [arch=amd64] $repo focal main" > /etc/apt/sources.list.d/newrelic-infra.list

RUN wget https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg -O - | apt-key add - && \
    apt update


FROM ubuntu-base

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
        apt install -y ${INTEGRATION} || ( [ "${FAIL_REPO}" = "false" ] && echo "⚠️ Previous version install failed, proceeding anyway" ); \
    fi; \
    if [ "${INSTALL_LOCAL}" = "true" ]; then \
        apt install -y "./dist/${INTEGRATION}_${TAG}-1_amd64.deb"; \
    fi
