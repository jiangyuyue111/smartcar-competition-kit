param(
    [Parameter(Mandatory = $true)]
    [string]$BusId
)

$ErrorActionPreference = "Stop"
if (-not (Get-Command usbipd.exe -ErrorAction SilentlyContinue)) {
    throw "usbipd-win is not installed."
}

usbipd.exe detach --busid $BusId
if ($LASTEXITCODE -ne 0) {
    throw "Camera detach failed."
}
