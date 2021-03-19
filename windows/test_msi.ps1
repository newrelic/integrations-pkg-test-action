param (
    [string]$INTEGRATION = "nri-test",
    [string]$ARCH = "amd64",
    [string]$TAG = "v0.0.0",
    [string]$UPGRADE = "false", # upgrade: upgrade msi from last released version.
    [string]$PKG_DIR = "",
    [string]$PKG_NAME = "",
    [string]$PKG_LATEST_NAME = "",
    [string]$PKG_LATEST_URL = ""
)

if ($PKG_LATEST_NAME -eq "")
{
    $PKG_LATEST_NAME = "${INTEGRATION}-${ARCH}.msi"
}
if ($PKG_LATEST_URL -eq "")
{
    $PKG_LATEST_URL = "https://download.newrelic.com/infrastructure_agent/windows/integrations/${INTEGRATION}/${PKG_LATEST_NAME}"
}

if ($UPGRADE -eq "true")
{
    write-host "ℹ️ Downloading latest released version of msi from ${PKG_LATEST_URL}"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try
    {
        Invoke-WebRequest "${PKG_LATEST_URL}" -OutFile "${PKG_LATEST_NAME}"
    }
    catch
    {
        write-host "⚠️ Couldn't fetch latest version from ${PKG_LATEST_URL}, skipping test"
        exit 0
    }

    write-host "::group::ℹ️ Installing latest released version of msi from ${PKG_LATEST_URL}"
    if ($PKG_LATEST_NAME -notlike "*.msi")
    {
        $p = Start-Process "$PKG_LATEST_NAME" -Wait -PassThru -ArgumentList "/s /l installer_log"
    }
    else
    {
        $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/qn /L*v installer_log /i $PKG_LATEST_NAME"
    }
    Get-Content -Path .\installer_log
    write-host "::endgroup::"
    if ($p.ExitCode -ne 0)
    {
        echo "❌ Failed installing latest version of the msi"
        exit 1
    }
    echo "✅ Installation for ${PKG_LATEST_NAME} succeeded"
}

$version = $TAG -replace "v", ""
if ($PKG_DIR -eq "")
{
    $PKG_DIR = "src\github.com\newrelic\${INTEGRATION}\build\package\windows\nri-${ARCH}-installer\bin\Release"
}
if ($PKG_NAME -eq "")
{
    $PKG_NAME = "${INTEGRATION}-${ARCH}.${version}.msi"
}
$PKG_LATEST_NAME = "${PKG_DIR}\${PKG_NAME}"
write-host "::group::ℹ️ Installing generated msi: ${PKG_LATEST_NAME}"
if ($PKG_LATEST_NAME -notlike "*.msi")
{
    $p = Start-Process "$PKG_LATEST_NAME" -Wait -PassThru -ArgumentList "/s /l installer_log"
}
else
{
    $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/qn /L*v installer_log /i ${PKG_LATEST_NAME}"
}
Get-Content -Path .\installer_log
write-host "::endgroup::"

if ($p.ExitCode -ne 0)
{
    echo "❌ Failed installing the msi"
    exit 1
}
echo "✅ Installation for ${PKG_LATEST_NAME} succeeded"

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
