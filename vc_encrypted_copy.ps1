Param(
  [Parameter(Mandatory=$true)][string]$in,
  [Parameter(Mandatory=$true)][string]$out,
  [string]$fs="fat",
  [string]$hash="sha-512",
  [string]$enc="AES",
  [string]$letter="z",
  [string]$containerSize="0"
)

function Test-File([string]$path) {
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

function getMinContainerSize([int64]$size) {
  switch ( $size ) {
    {$_ -le 5MB} {
      6MB
      break
    }
    {$_ -le 100MB} {
      [int64]($size * 1.05)
      break
    }
    {$_ -le 1GB} {
      [int64]($size * 1.01)
      break
    }
    default {
      [int64]($size * 1.01)
      break
    }
  }
}

function convertRequestedContainerSizeStr([string]$size) {
  switch ($size) {
    {$_ -cmatch "\d+TB"} {
      [int]$_.Replace('TB', '') * 1TB
      break
    }
    {$_ -cmatch "\d+GB"} {
      [int]$_.Replace('GB', '') * 1GB
      break
    }
    {$_ -cmatch "\d+MB"} {
      [int]$_.Replace('MB', '') * 1MB
      break
    }
    {[string]::IsNullOrEmpty($_)} {
      0
      break
    }
    default {
       Write-Error "Wrong requested container size - $size - should be in format '{0..9}+[TB|GB|MB]'" -ErrorAction Stop
    }
  }
}

$driveLetter = $letter+":"

if (Test-Path $out) {
  Write-Error "Wrong path for output container - file exists" -ErrorAction Stop
}

if (Test-Path $driveLetter) {
  Write-Error "Wrong drive letter for mounting container" -ErrorAction Stop
}

$items = Get-ChildItem -Recurse -Path $in

$size = ($items | Measure-Object -Sum Length).Sum

$minContainerSize = getMinContainerSize($size)
$contSize = convertRequestedContainerSizeStr($containerSize)

if ($contSize -ne 0) {
  if ($contSize -lt $minContainerSize) {
    Write-Error "Forced container size $contSize it too small - minimal container size is $minContainerSize" -ErrorAction Stop
  }
  $size = $contSize
} else {
  $size = $minContainerSize
}

$securePassword = Read-Host -Prompt "Enter password" -AsSecureString 
$pass = Convert-ToString $securePassword

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