ARG BASE_IMAGE
FROM $BASE_IMAGE as base

ARG DISTRO
ENV DISTRO=$DISTRO

ARG ACTION_PATH=.
COPY $ACTION_PATH/helper*.sh /

ARG STAGING_REPO=false
ENV STAGING_REPO=$STAGING_REPO

# Run helper prepare. This adds the NR repo and installs the agent
RUN /helper.sh prepare


FROM base

ARG PKGDIR=./dist
COPY ${PKGDIR} ./dist

ARG INTEGRATION
ARG TAG
ARG INSTALL_REPO=false
ARG FAIL_REPO=false
ARG INSTALL_LOCAL=true

# Run helper install, which will:
# - Install the integration from the repo, if INSTALL_REPO==true
#   + Exit with an error if that fails and FAIL_REPO==true
#   + This is helpful when doing an upgrade test, in which we want to install from the repo but
#     not to fail the test if that fails (e.g. integration is new and no upstream version exists)
# - Install the integration from a local file if INSTALL_LOCAL==true
#   + Local file name is defined on each of the helper_*.sh variants
RUN INTEGRATION=$INTEGRATION \
    TAG=$TAG \
    INSTALL_REPO=$INSTALL_REPO \
    FAIL_REPO=$FAIL_REPO \
    INSTALL_LOCAL=$INSTALL_LOCAL \
    /helper.sh install