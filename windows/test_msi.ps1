$INTEGRATION = if ($env:integration) {"$env:integration"} else {"nri-test"};
$ARCH  = if ($env:arch) {"$env:arch"} else {"amd64"};
$TAG = if ($env:tag) {"$env:tag"} else {"v0.0.0"};
$UPGRADE = if ($env:upgrade) {"$env:upgrade"} else {"false"}; # upgrade: upgrade msi from last released version.
$PKG_TYPE = if ($env:pkgType) {"$env:pkgType"} else {"msi"};
$PKG_DIR = "$env:pkgDir"
$PKG_NAME = "$env:pkgName"
$PKG_UPSTREAM_URL_BASE = "$env:pkgUpstreamBaseURL"
$PKG_UPSTREAM_NAME = "$env:pkgLatestName"
$REPO_VERSION = "$env:repoVersion"

if ($PKG_TYPE -NotMatch "msi" -And $PKG_TYPE -NotMatch "exe") {
    echo "❌ PKG_TYPE can only be 'msi' or 'exe'"
    exit 1
}

$version = ""
if ($REPO_VERSION -ne "")
{
    $version = ".$REPO_VERSION" -replace "v", ""
}
if ($PKG_UPSTREAM_NAME -eq "")
{
    if ($PKG_TYPE -eq "msi")
    {
        $PKG_UPSTREAM_NAME = "${INTEGRATION}-${ARCH}${version}.msi"
    }
    elseif ($PKG_TYPE -eq "exe")
    {
        $PKG_UPSTREAM_NAME = "${INTEGRATION}-${ARCH}${version}-installer.exe"
    }
}

if ($PKG_UPSTREAM_URL_BASE -eq "")
{
    $PKG_UPSTREAM_URL_BASE = "http://nr-downloads-main.s3-website-us-east-1.amazonaws.com/infrastructure_agent/windows/integrations/${INTEGRATION}/"
}

$PKG_UPSTREAM_URL = "${PKG_UPSTREAM_URL_BASE}${PKG_UPSTREAM_NAME}"

if ($UPGRADE -eq "true")
{
    write-host "ℹ️ Downloading latest released version of msi from ${PKG_UPSTREAM_URL}"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try
    {
        Invoke-WebRequest "${PKG_UPSTREAM_URL}" -OutFile "${PKG_UPSTREAM_NAME}"
    }
    catch
    {
        write-host "⚠️ Couldn't fetch latest version from ${PKG_UPSTREAM_URL}, skipping test"
        exit 0
    }

    write-host "::group::ℹ️ Installing latest released version of msi from ${PKG_UPSTREAM_URL}"
    if ($PKG_TYPE -eq "exe")
    {
        $p = Start-Process "$PKG_UPSTREAM_NAME" -Wait -PassThru -ArgumentList "/s /l installer_log"
    }
    elseif ($PKG_TYPE -eq "msi")
    {
        $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/qn /L*v installer_log /i $PKG_UPSTREAM_NAME"
    }
    Get-Content -Path .\installer_log
    write-host "::endgroup::"
    if ($p.ExitCode -ne 0)
    {
        echo "❌ Failed installing latest version of the msi"
        exit 1
    }
    echo "✅ Installation for ${PKG_UPSTREAM_NAME} succeeded"
}

$version = "$TAG" -replace "v", ""
if ($PKG_DIR -eq "")
{
    # Default path also differs depending on the package type
    if ($PKG_TYPE -eq "msi")
    {
        $PKG_DIR = "src\github.com\newrelic\${INTEGRATION}\build\package\windows\nri-${ARCH}-installer\bin\Release"
    }
    elseif ($PKG_TYPE -eq "exe")
    {
        $PKG_DIR = "src\github.com\newrelic\${INTEGRATION}\build\package\windows\bundle\bin\Release"
    }
}
if ($PKG_NAME -eq "")
{
    if ($PKG_TYPE -eq "msi")
    {
        $PKG_NAME = "${INTEGRATION}-${ARCH}.${version}.msi"
    }
    elseif ($PKG_TYPE -eq "exe")
    {
        $PKG_NAME = "${INTEGRATION}-${ARCH}-installer.${version}.exe"
    }
}
$PKG_PATH = Join-Path -Path "$PKG_DIR" -ChildPath "$PKG_NAME"

write-host "::group::ℹ️ Installing generated msi: ${PKG_PATH}"
if ($PKG_TYPE -eq "exe")
{
    $p = Start-Process "$PKG_PATH" -Wait -PassThru -ArgumentList "/s /l installer_log"
}
elseif ($PKG_TYPE -eq "msi")
{
    $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/qn /L*v installer_log /i ${PKG_PATH}"
}
Get-Content -Path .\installer_log
write-host "::endgroup::"

if ($p.ExitCode -ne 0)
{
    echo "❌ Failed installing the msi"
    exit 1
}
echo "✅ Installation for ${PKG_PATH} succeeded"

$nr_base_dir = "${env:ProgramFiles}\New Relic\newrelic-infra"
if ($ARCH -eq "386")
{
    $nr_base_dir = "${env:ProgramFiles(x86)}\New Relic\newrelic-infra"
}
$bin_installed = "${nr_base_dir}\newrelic-integrations\bin\${INTEGRATION}.exe"

write-host "::group::ℹ️ Check binary version: ${bin_installed}"
$out = & "$bin_installed" -show_version 2>&1
write-host "$out"
write-host "::endgroup::"
if ($out -notlike "*${version}*")
{
    echo "❌ Failed checking binary version"
    exit 1
}
echo "✅ Version check succeeded"
