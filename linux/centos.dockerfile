FROM centos:centos8 as centos-base

# Installing needed tools
RUN yum update -y && \
    yum install -y wget

# Adding Newrelic repository
RUN wget -O /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/8/x86_64/newrelic-infra.repo && \
    yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra' && \
    yum update -y && \
    yum -y install newrelic-infra


FROM centos-base

ARG INTEGRATION
ARG TAG
ARG PKGDIR=./dist
ARG UPGRADE=false

ADD ${PKGDIR} ./dist

RUN if [ "${UPGRADE}" = "true" ]; then \
        yum -y install ${INTEGRATION} || echo "⚠️ Previous version install failed, proceeding anyway"; \
    fi; \
    yum -y install ./dist/${INTEGRATION}-${TAG}-1.x86_64.rpm
