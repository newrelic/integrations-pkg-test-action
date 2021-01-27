FROM opensuse/tumbleweed as suse-base

# Installing needed tools
RUN zypper -n install wget gnupg curl

# Adding Newrelic repository
RUN curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg -s |  gpg --import && \
    curl -o /etc/zypp/repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/zypp/sles/12.4/x86_64/newrelic-infra.repo && \
    zypper --gpg-auto-import-keys ref && \
    zypper -n ref -r newrelic-infra && \
    zypper -n install newrelic-infra


FROM suse-base

ARG INTEGRATION
ARG TAG
ARG PKGDIR=./dist
ARG UPGRADE=false

ADD ${PKGDIR} ./dist

RUN if [ "${UPGRADE}" = "true" ]; then zypper -n install ${INTEGRATION}; fi; \
    zypper -n install ./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm
