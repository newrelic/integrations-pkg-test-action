FROM centos:centos8 as centos-base

ARG STAGING_REPO=false

# Installing needed tools
RUN yum update -y && \
    yum install -y wget

# Adding Newrelic repository
RUN if [ "${STAGING_REPO}" = "true" ]; then \
        repo="http://nr-downloads-ohai-staging.s3-website-us-east-1.amazonaws.com/infrastructure_agent/linux/yum/el/8/x86_64/newrelic-infra.repo"; \
    else \
        repo="https://download.newrelic.com/infrastructure_agent/linux/yum/el/8/x86_64/newrelic-infra.repo"; \
    fi; \
    wget -O /etc/yum.repos.d/newrelic-infra.repo "$repo"

RUN yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra' && \
    yum update -y && \
    yum -y install newrelic-infra


FROM centos-base

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
        yum -y install ${INTEGRATION} || ( [ "${FAIL_REPO}" = "false" ] && echo "⚠️ Previous version install failed, proceeding anyway" ); \
    fi; \
    if [ "${INSTALL_LOCAL}" = "true" ]; then \
            yum -y install "./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm"; \
    fi
