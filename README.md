[![Community Project header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Project.png)](https://opensource.newrelic.com/oss-category/#community-project)
# integrations-pkg-test-action

An action to test for correct installation and upgrades of New Relic integration packages.
It tests clean installation and upgrade for integration packages in CentOS, Suse and Ubuntu, as well as in Windows.

## Usage

### `/linux`

Usage and defaults:
```yaml
    - name: Test packages installation
      uses: paologallinaharbur/test-packages-action/linux@v1
      with:
        tag: ${{ env.TAG }} # Required, trailing v is stripped automatically if found
        integration: 'nri-${{ env.INTEGRATION }}' # Required, with nri- prefix
```

#### Extra parameters

The following inputs can be specified to override the default behavior

* `upgrade`: Whether to test upgrade path against the version of the same integration in the newrelic repo
    - default: `true`
* `postInstallExtra`: Extra checks to run in addition to the default post-install script. This is specified as a multi-line shell script, which is run line-by-line in different containers. A non-zero exit code for any line causes the installation check to fail.
    - default: empty
* `postInstall`: Override the post-install test script. This is run line-by-line in different containers. A non-zero exit code causes the install check to fail.
    - default: See `entrypoint.sh`
* `distros`: Space-separated list of distros to run the test on. Supported values are "ubuntu", "suse" and "centos"
    - default: `centos suse ubuntu`
* `pkgDir`: Path where archives (.deb and .rpm) reside
    - default: `./dist`

### `/windows`

Usage and defaults:
```yaml
    - name: Test packages installation
      uses: paologallinaharbur/test-packages-action/windows@v1
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

New Relic hosts and moderates an online forum where customers can interact with New Relic employees as well as other customers to get help and share best practices. Like all official New Relic open source projects, there's a related Community topic in the New Relic Explorers Hub. You can find this project's topic/threads here:

>Add the url for the support thread here: discuss.newrelic.com

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
