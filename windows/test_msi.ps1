
param (
    [string]$INTEGRATION="nri-test",
    [string]$ARCH="amd64",
    [string]$TAG="v0.0.0",
    [string]$UPGRADE="false", # upgrade: upgrade msi from last released version.
    [string]$MSI_PATH=""
)

if($UPGRADE -eq "true")
{
    $latest_msi_name = "${INTEGRATION}-${ARCH}.msi"
    $latest_msi_url = "https://download.newrelic.com/infrastructure_agent/windows/integrations/${INTEGRATION}/${latest_msi_name}"
    write-host "===> Downloading latest released version of msi from ${latest_msi_url}"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest "${latest_msi_url}" -OutFile "${latest_msi_name}"
    } catch {
        write-host "⚠️ Couldn't fetch latest version from ${latest_msi_url}, skipping test"
        exit 0
    }

    write-host "===> Installing latest released version of msi from ${latest_msi_url}"
    $p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/qn /L*v msi_log /i ${latest_msi_name}"
    if($p.ExitCode -ne 0)
    {
        Get-Content -Path .\msi_log
        echo "Failed installing latest version of the msi"
        exit 1
    }
}

$version = $TAG -replace "v", ""
if($MSI_PATH -eq "")
{
    $MSI_PATH="src\github.com\newrelic\${INTEGRATION}\build\package\windows\nri-${ARCH}-installer\bin\Release"    
}
$msi_name = "$MSI_PATH\${INTEGRATION}-${ARCH}.${version}.msi"
write-host "===> Installing generated msi: ${msi_name}"
$p = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/qn /L*v msi_log /i ${msi_name}"
if($p.ExitCode -ne 0)
{
    Get-Content -Path .\msi_log
    echo "Failed installing the msi"
    exit 1
}

$nr_base_dir = "${env:ProgramFiles}\New Relic\newrelic-infra"
if($ARCH -eq "386")
{
    $nr_base_dir = "${env:ProgramFiles(x86)}\New Relic\newrelic-infra"
}
$bin_installed = "${nr_base_dir}\newrelic-integrations\bin\${INTEGRATION}.exe"

write-host "===> Check binary version: ${bin_installed}"
$out = & ${bin_installed} "-show_version" 2>&1
if( $out -notlike "*${version}*")
{
    echo "Failed checking binary version"
    exit 1
}
