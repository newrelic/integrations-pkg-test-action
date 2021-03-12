FROM ubuntu:focal as ubuntu-base

# Installing needed tools
RUN apt update && \
    apt -y install wget gnupg

ARG AGENT_PACKAGE=newrelic-infra_upstart_1.14.2_upstart_amd64.deb
# Installing Agent
RUN wget https://download.newrelic.com/infrastructure_agent/linux/apt/pool/main/n/newrelic-infra/${AGENT_PACKAGE} && \
    apt install ./${AGENT_PACKAGE}

# Adding Newrelic repository
RUN wget https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg -O - | apt-key add - && \
    echo "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt focal main" > /etc/apt/sources.list.d/newrelic-infra.list && \
    apt update

# By default, dockerized ubuntu drops files in /usr/share/doc when installing. We do not want this, as we want
# to be able to test for their existence
RUN rm /etc/dpkg/dpkg.cfg.d/excludes || true


FROM ubuntu-base

ARG INTEGRATION
ARG TAG
ARG PKGDIR=./dist
ARG INSTALL_REPO=false
ARG INSTALL_LOCAL=true

ADD ${PKGDIR} ./dist

RUN if [ "${INSTALL_REPO}" = "true" ]; then \
        apt install -y ${INTEGRATION} || echo "⚠️ Previous version install failed, proceeding anyway"; \
    fi; \
    if [ "${INSTALL_LOCAL}" = "true" ]; then \
        apt install -y "./dist/${INTEGRATION}_${TAG}-1_amd64.deb"; \
    fi
