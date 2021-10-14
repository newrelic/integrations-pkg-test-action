[![Community Project header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Project.png)](https://opensource.newrelic.com/oss-category/#community-project)

# integrations-pkg-test-action

An action to test for correct installation and upgrades of New Relic integration packages.
It tests clean installation and upgrade for integration packages in CentOS, Suse and Ubuntu, as well as in Windows.

## Usage

### `/linux`

Usage and defaults:

Test local packages produced in the `dist` folder:
```yaml
- name: Test packages installation
  uses: newrelic/integrations-pkg-test-action/linux@v1
  with:
    tag: ${{ env.TAG }} # Required, trailing v is stripped automatically if found
    integration: 'nri-${{ env.INTEGRATION }}' # Required, with nri- prefix
```

Test packages uploaded to the staging repos:

> Note: When `packageLocation == repo`, `tag` does *not* specify which version is downloaded from the repo (which is always the latest available).
> However, `tag` will be used to compare against the `-show_version` output and ensure the installed version is the desired one.

```yaml
- name: Test staging repo
  uses: newrelic/integrations-pkg-test-action/linux@v1
  with:
    tag: ${{ env.TAG }}
    integration: 'nri-${{ env.INTEGRATION }}' # Required, with nri- prefix
    stagingRepo: true
    packageLocation: repo
    upgrade: false # Upgrade path test does not make sense when testing the repo
```

#### Extra parameters

The following inputs can be specified to override the default behavior

* `upgrade`: Whether to test upgrade path against the version of the same integration in the newrelic repo
  - default: `true`
* `postInstallExtra`: Extra checks to run in addition to the default post-install script. This is specified as a multi-line shell script, which is run line-by-line in different containers. A non-zero exit code for any line causes the installation check to fail.
  - default: empty
* `postInstall`: Override the post-install test script. This is run line-by-line in different containers. A non-zero exit code causes the install check to fail.
  - default: See `entrypoint.sh`
* `distros`: Space-separated list of distros to run the test on. See below for details.
* `packageLocation`: Whether to test local packages (`local`) or packages from the upstream repo (`repo`). Useful for testing the staging repo.
  - *Note: Specifying both `packageLocation: repo` and `upgrade: true` is not possible and such combination will be silently ignored.*
  - default: `local`
* `stagingRepo`: Pull repo packages from the staging repo rather than production. Useful for testing staging repo packages alone (rather than local).
  - default: `false`
* `pkgDir`: Path where archives (.deb and .rpm) reside
  - default: `./dist`

##### Supported `distros`

Distros to test on are supplied as docker tags, provided that a mapping between the tag and a helper script is available for it. Mapping between tags and helpers can be found here: https://github.com/newrelic/integrations-pkg-test-action/blob/master/linux/helper.sh#L8

If a mapping exists for the docker image, the associated helper script will be responsible of adding to the image the corresponding repository for that particular tag.

Despite not being docker tags, `action.sh` will also [accept](https://github.com/newrelic/integrations-pkg-test-action/blob/master/linux/action.sh#L27) the following values:
* `ubuntu`
* `suse`
* `centos`
* `debian`

#### Running locally

This action is mainly contained in one shell script (and a few dockerfiles) and can be run in systems which have a bash-compatible shell and docker installed.

Inputs are taken as environment vars, transforming `camelCase` to `UPPERCASE_WITH_UNDERSCORES`. Additionally, `GITHUB_ACTION_PATH` must be specified if WD is not the `linux/` directory.

Test local packages:
```bash
GITHUB_ACTION_PATH=./linux TAG=v1.3.0 INTEGRATION=nri-snmp ./linux/action.sh
```

Test staging repo packages:
```bash
STAGING_REPO=true PACKAGE_LOCATION=repo PKGDIR=testdata/dist GITHUB_ACTION_PATH=./linux TAG=v1.3.0 INTEGRATION=nri-snmp ./linux/action.sh
```

### `/windows`

Usage and defaults:
```yaml
    - name: Test packages installation
      uses: newrelic/integrations-pkg-test-action/windows@v1
      with:
        tag: ${{ env.TAG }} # Required, trailing v is stripped automatically if found
        integration: 'nri-${{ env.INTEGRATION }}' # Required, with nri- prefix
        arch: 'amd64' # Architecture to test [amd64, 386]
```
#### Extra parameters

The following inputs can be specified to override the default behavior

* `upgrade`: Whether to test upgrade path against the version of the same integration in the newrelic repo
  - default: `true`
* `pkgDir`: Path where archives (.msi) reside
  - default: `build\package\windows\nri-${ARCH}-installer\bin\Release`

## Support

New Relic hosts and moderates an online forum where customers can interact with New Relic employees as well as other customers to get help and share best practices. Like all official New Relic open source projects, there's a related Community topic in the New Relic Explorers Hub.

## Contribute

We encourage your contributions to improve this action! Keep in mind that when you submit your pull request, you'll need to sign the CLA via the click-through using CLA-Assistant. You only have to sign the CLA one time per project.

If you have any questions, or to execute our corporate CLA (which is required if your contribution is on behalf of a company), drop us an email at opensource@newrelic.com.

**A note about vulnerabilities**

As noted in our [security policy](../../security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).

If you would like to contribute to this project, review [these guidelines](./CONTRIBUTING.md).

To all contributors, we thank you!  Without your contribution, this project would not be what it is today.  We also host a community project page dedicated to [Project Name](<LINK TO https://opensource.newrelic.com/projects/... PAGE>).

## License
integrations-pkg-test-action is licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.
