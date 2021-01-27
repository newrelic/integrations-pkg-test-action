# test-packages-action

An action to test for correct installation and upgrades of New Relic integration packages.
It tests clean installation and upgrade for integration packages in CentOS, Suse and Ubuntu, as well as in Windows.

## `/linux`

Usage and defaults:
```yaml
    - name: Test packages installation
      uses: paologallinaharbur/test-packages-action/linux@v1
      with:
        tag: ${{ env.TAG }} # Required, trailing v is stripped automatically if found
        integration: 'nri-${{ env.INTEGRATION }}' # Required, with nri- prefix
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

Usage and defaults:
```yaml
    - name: Test packages installation
      uses: paologallinaharbur/test-packages-action/linux@v1
      with:
        tag: ${{ env.TAG }} # Required, trailing v is stripped automatically if found
        integration: 'nri-${{ env.INTEGRATION }}' # Required, with nri- prefix
        arch: 'amd64' # Architecture to test [amd64, 386]
```
### Extra parameters

The following inputs can be specified to override the default behavior 

* `upgrade`: Whether to test upgrade path against the version of the same integration in the newrelic repo
  - default: `true`
* `pkgDir`: Path where archives (.msi) reside
  - default: `build\package\windows\nri-${ARCH}-installer\bin\Release`
