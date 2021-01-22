# test-packages-action

Usage:
```yaml
    - name: Test packages installation
      uses: paologallinaharbur/test-packages-action@v1.0.5
      with:
        TAG: '0.0.1'
        INTEGRATION: 'nri-apache'
        TEST_EXISTENCE: 'file1 file2 file3'
```