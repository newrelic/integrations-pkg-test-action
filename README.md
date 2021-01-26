# test-packages-action

## `/linux`

An action to test for correct installation and upgrades of New Relic integration packages.

It tests clean installation and upgrade for integration packages in CentOS, Suse and Ubuntu.

Usage and defaults:
```yaml
    - name: Test packages installation
      uses: paologallinaharbur/test-packages-action/linux@main # sample only, do not use `main` in production
      with:
        tag: '0.0.1' # Required, trailing v is stripped automatically if found
        integration: 'nri-apache' # Required, with nri-prefix
```

### Extra parameters

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

## `/windows`

WIP
