# Dev documentation

This doc briefly describes the architecture and moving parts of the integrations-pkg-test-action.

## Overview

The action works by spinning docker containers, adding the NR repo and the infra agent to them, and try to install the specified integration, checking for errors.
After that, several `docker run` commands are run in the produced images, which check for existence of several files and if the integration binary is able to run correctly.

## Architecture

### `action.sh`

The `action.sh` script is the entrypoint to the action (and can also be run locally). Key responsibilities are parsing input parameters, running `docker build` with them, and then running `docker run` for each test command. Most of the logic for actually installing packages and dependencies are in `helper.sh`, which is invoked in the `Dockerfile`.

The action offers a `packageLocation` and `upgrade` inputs, which dictate which location should be tested (local file or remote), and if the upgrade path should be tested for a local file. These are abstractions of the underlying implementation, and `action.sh` translates these into the more basic `INSTALL_REPO`, `FAIL_REPO` and `INSTALL_LOCAL` parameters, which are then parsed by `helper.sh`. 

After as successful build of the image, this script will split the lines in the `POST_INSTALL` var and run them as single commants using `docker run`. If they were to fail, the installation test will fail.

### `helper.sh`

The helper script is responsible of doing the heavy lifting in the build step of the docker image. It is similar to an installer script, with very through error checking.

Additionally, this script defines some sort of "interface" to make easy to test more distros. This interface are just the following four functions:

- `add_repo`: Add the NR repo to the system. It must read `STAGING_REPO` from env and add the staging repo if it is `"true"`.
- `install_agent`: Install the infra agent, which is a dependency for all integrations.
- `install_repo` Install the integration from the repo. It must read `INTEGRATION` from env to get the package name.
- `install_local` Install the integration from a local package in the `./dist` folder. It must read `INTEGRATION` and `TAG` from env to form the package name, following New Relick package naming conventions for each format.

`helper.sh` has two subcommands:

- `helper.sh prepare`: Adds the repository and installs the agent and some build-time dependencies. Invokes `add_repo` and `install_agent`. This step is not supposed to fail.
- `helper.sh install`: Invokes `install_repo` and/or `install_local` and checks for errors, all according to the values of `INSTALL_REPO`, `FAIL_REPO` and `INSTALL_LOCAL`.

### `Dockerfile`

The dockerfile is intended to be universal to all linux distros. It requires many build args, but most of them are just passed to `helper.sh` as env vars. The dockerfile itself will consume:

- `BASE_IMAGE`: Used as in `FROM $BASE_IMAGE`. This value is derived from the `distro` input in `action.sh`, using a map of well-known images.
- `ACTION_PATH`: path to the `linux` folder of this action, relative to the WD. Used to copy the `helper.sh` script.
