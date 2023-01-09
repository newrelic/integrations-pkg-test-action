ARG BASE_IMAGE
FROM $BASE_IMAGE as base

WORKDIR /integration

ARG BASE_IMAGE
ENV BASE_IMAGE=$BASE_IMAGE

# Copy helper scripts
COPY helper*.sh rpm-repos/*.repo ./

ARG STAGING_REPO=false
ENV STAGING_REPO=$STAGING_REPO

# Run helper prepare. This adds the NR repo and installs the agent
RUN ./helper.sh prepare


FROM base

# Copy packages to be tested
COPY ./dist ./dist

ARG INTEGRATION
ARG REPO_VERSION
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
    REPO_VERSION=$REPO_VERSION \
    TAG=$TAG \
    INSTALL_REPO=$INSTALL_REPO \
    FAIL_REPO=$FAIL_REPO \
    INSTALL_LOCAL=$INSTALL_LOCAL \
    ./helper.sh install
