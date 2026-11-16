param(
    [Parameter(Mandatory = $true)]
    [string]$BusId,

    [string]$Distribution = "Ubuntu",

    [switch]$AutoAttach
)

$ErrorActionPreference = "Stop"
if (-not (Get-Command usbipd.exe -ErrorAction SilentlyContinue)) {
    throw "usbipd-win is not installed. Install it before attaching a camera to WSL."
}

usbipd.exe bind --busid $BusId
if ($LASTEXITCODE -ne 0) {
    throw "Binding failed. Run PowerShell as Administrator for the first bind."
}

$arguments = @("attach", "--wsl", $Distribution, "--busid", $BusId)
if ($AutoAttach) {
    $arguments += "--auto-attach"
}

if ($AutoAttach) {
    Start-Process -FilePath "usbipd.exe" -ArgumentList $arguments -WindowStyle Hidden
    Write-Output "Auto-attach monitoring started for USB bus $BusId."
} else {
    usbipd.exe @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Camera attach failed."
    }
}
