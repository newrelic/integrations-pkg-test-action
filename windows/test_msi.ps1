param (
    [string]$INTEGRATION = "nri-test",
    [string]$ARCH = "amd64",
    [string]$TAG = "v0.0.0",
    [string]$UPGRADE = "false", # upgrade: upgrade msi from last released version.
    [string]$MSI_PATH = "",
    [string]$MSI_FILE_NAME = "",
    [string]$LATEST_MSI_NAME = "",
    [string]$LATEST_MSI_URL = ""
)

if ($LATEST_MSI_NAME -eq "")
{
    $LATEST_MSI_NAME = "${INTEGRATION}-${ARCH}.msi"
}
if ($LATEST_MSI_URL -eq "")
{
    $LATEST_MSI_URL = "https://download.newrelic.com/infrastructure_agent/windows/integrations/${INTEGRATION}/${LATEST_MSI_NAME}"
}

if ($UPGRADE -eq "true")
{
    write-host "ℹ️ Downloading latest released version of msi from ${LATEST_MSI_URL}"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try
    {
        Invoke-WebRequest "${LATEST_MSI_URL}" -OutFile "${LATEST_MSI_NAME}"
    }
    catch
    {
        write-host "⚠️ Couldn't fetch latest version from ${LATEST_MSI_URL}, skipping test"
        exit 0
    }

    write-host "::group::ℹ️ Installing latest released version of msi from ${LATEST_MSI_URL}"
    if ($out -notlike "*.msi")
    {
        $p = Start-Process ${LATEST_MSI_NAME} -Wait -PassThru -ArgumentList "/s /l installer_log"
    }
    else
    {
        $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/qn /L*v installer_log /i ${LATEST_MSI_NAME}"
    }
    Get-Content -Path .\installer_log
    write-host "::endgroup::"
    if ($p.ExitCode -ne 0)
    {
        echo "❌ Failed installing latest version of the msi"
        exit 1
    }
    echo "✅ Installation for ${LATEST_MSI_NAME} succeeded"
}

$version = $TAG -replace "v", ""
if ($MSI_PATH -eq "")
{
    $MSI_PATH = "src\github.com\newrelic\${INTEGRATION}\build\package\windows\nri-${ARCH}-installer\bin\Release"
}
if ($MSI_FILE_NAME -eq "")
{
    $MSI_FILE_NAME = "${INTEGRATION}-${ARCH}.${version}.msi"
}
$msi_name = "${MSI_PATH}\${MSI_FILE_NAME}"
write-host "::group::ℹ️ Installing generated msi: ${msi_name}"
if ($out -notlike "*.msi")
{
    $p = Start-Process ${msi_name} -Wait -PassThru -ArgumentList "/s /l installer_log"
}
else
{
    $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/qn /L*v installer_log /i ${msi_name}"
}
Get-Content -Path .\installer_log
write-host "::endgroup::"

if ($p.ExitCode -ne 0)
{
    echo "❌ Failed installing the msi"
    exit 1
}
echo "✅ Installation for ${msi_name} succeeded"

$nr_base_dir = "${env:ProgramFiles}\New Relic\newrelic-infra"
if ($ARCH -eq "386")
{
    $nr_base_dir = "${env:ProgramFiles(x86)}\New Relic\newrelic-infra"
}
$bin_installed = "${nr_base_dir}\newrelic-integrations\bin\${INTEGRATION}.exe"

write-host "::group::ℹ️ Check binary version: ${bin_installed}"
$out = & ${bin_installed} "-show_version" 2>&1
write-host "$out"
write-host "::endgroup::"
if ($out -notlike "*${version}*")
{
    echo "❌ Failed checking binary version"
    exit 1
}
echo "✅ Version check succeeded"
