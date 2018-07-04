Param(
  [Parameter(Mandatory=$true)][string]$in,
  [Parameter(Mandatory=$true)][string]$out,
  [string]$fs="fat",
  [string]$hash="sha-512",
  [string]$enc="AES",
  [string]$letter="z"
)

function Test-File([string] $path) {
  if (!(Test-Path $Path)) {
    return $false
  }
  try { 
    [IO.File]::OpenWrite($path).close();
    $true 
  }
  catch {
    $false
  }
}

function Convert-ToString([System.Security.SecureString]$secstr) {
  [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secstr))
}

function containerSize($size) {
  switch ( $size ) {
    {$_ -le 5MB} {
      5MB
      break
    }
    {$_ -le 100MB} {
      [int]($size * 1.05)
      break
    }
    {$_ -le 1GB} {
      [int]($size * 1.01)
      break
    }
    default {
      [int]($size * 1.005)
      break
    }
  }
}

$securePassword = Read-Host -Prompt "Enter password" -AsSecureString 
$pass = Convert-ToString $securePassword

$driveLetter = $letter+":"

if (Test-Path $out) {
  Write-Error "Wrong path for output container - file exists" -ErrorAction Stop
}

if (Test-Path $driveLetter) {
  Write-Error "Wrong drive letter for mounting container" -ErrorAction Stop
}

$items = Get-ChildItem -Recurse -Path $in

$size = ($items | Measure-Object -Sum Length).Sum
$size = containerSize($size)


Write-Output "Creating container - $out - size: $size"
& "VeraCrypt Format.exe" /create "$out" /size "$size" /filesystem "$fs" /encryption "$enc" /password "$pass" /hash "$hash" /silent 

while (!(Test-File "$out")) { Start-Sleep 1 }

Write-Output "Mounting container - letter: $letter"
Veracrypt.exe /hash "$hash" /volume "$out" /password "$pass" /auto /letter "$letter" /history n /quit

while (!(Test-Path $driveLetter)) { Start-Sleep 1 }

Write-Output "Container mounted"
Write-Output "Copying data"

copy-item "$in" "$driveLetter\" -force -recurse

Write-Output "Data copied"
Write-Output "Container unmounting"
Veracrypt.exe /dismount "$letter" /quit

while (!(Test-File "$out")) { Start-Sleep 1 }

Write-Output "Container unmounted"
Write-Output "Done!"