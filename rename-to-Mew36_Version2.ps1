# rename-to-Mew36.ps1
# Chạy trong thư mục repo: PowerShell -> .\rename-to-Mew36.ps1
# Script này:
#  - đổi tên file chứa ldt21 trong đường dẫn shields (git mv)
#  - thay LDT21 -> MEW36 (uppercase macros)
#  - thay ldt21 (case-insensitive) -> Mew36 (display/id)
#  - xóa file tạm
#  - hiển thị git grep và git status để bạn kiểm tra
#
# LƯU Ý: script không commit/push. Kiểm tra output rồi chạy git add/commit/push nếu ok.

# 1) Đổi tên file trong boards/shields/mew36 nếu tồn tại
$moves = @(
  @{ src="boards/shields/mew36/ldt21.dtsi"; dst="boards/shields/mew36/mew36.dtsi" },
  @{ src="boards/shields/mew36/ldt21.zmk.yml"; dst="boards/shields/mew36/mew36.zmk.yml" },
  @{ src="boards/shields/mew36/ldt21_left.overlay"; dst="boards/shields/mew36/mew36_left.overlay" },
  @{ src="boards/shields/mew36/ldt21_right.overlay"; dst="boards/shields/mew36/mew36_right.overlay" }
)
foreach ($m in $moves) {
  if (Test-Path $m.src) {
    Write-Output "git mv `"$($m.src)`" `"$($m.dst)`""
    git mv $m.src $m.dst
  } else {
    Write-Output "Not found (skip): $($m.src)"
  }
}

# 2) Remove temp files if present (safe)
$temps = @(".\files-to-change.txt", ".\files-uppercase.txt", ".\-to-change.txt", ".\rename-uppercase.ps1")
foreach ($t in $temps) {
  if (Test-Path $t) {
    Write-Output "Remove temp: $t"
    Remove-Item $t -Force -ErrorAction SilentlyContinue
  }
}

# Helper to run git grep safely and return array of files (or empty array)
function Get-GitGrepFiles {
  param(
    [string]$pattern,
    [switch]$ignoreCase
  )
  $args = @("grep","-l")
  if ($ignoreCase) { $args += "-i" }
  $args += $pattern
  # Run git grep; capture output and exit code
  $procInfo = New-Object System.Diagnostics.ProcessStartInfo
  $procInfo.FileName = "git"
  $procInfo.RedirectStandardOutput = $true
  $procInfo.RedirectStandardError = $true
  $procInfo.UseShellExecute = $false
  $procInfo.Arguments = $args -join " "
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $procInfo
  $p.Start() | Out-Null
  $out = $p.StandardOutput.ReadToEnd()
  $err = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  if ($p.ExitCode -ne 0 -and [string]::IsNullOrWhiteSpace($out)) {
    return @()
  }
  if ([string]::IsNullOrWhiteSpace($out)) { return @() }
  return $out -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}

# 3) Replace uppercase macros LDT21 -> MEW36 in text files found by git grep
$filesUpper = Get-GitGrepFiles -pattern "LDT21"
if ($filesUpper.Count -gt 0) {
  Write-Output "`nReplacing uppercase LDT21 -> MEW36 in these files:"
  $filesUpper | ForEach-Object { Write-Output "  $_" }
  foreach ($f in $filesUpper) {
    try {
      (Get-Content -LiteralPath $f -Raw) -replace 'LDT21','MEW36' | Set-Content -LiteralPath $f -Encoding UTF8
      Write-Output "Updated uppercase in $f"
    } catch {
      Write-Output "Failed to update (skip): $f - $_"
    }
  }
} else {
  Write-Output "`nNo uppercase LDT21 matches found."
}

# 4) Replace case-insensitive ldt21 -> Mew36 in text files found by git grep -i
$filesAll = Get-GitGrepFiles -pattern "ldt21" -ignoreCase
if ($filesAll.Count -gt 0) {
  Write-Output "`nReplacing case-insensitive ldt21 -> Mew36 in these files:"
  $filesAll | ForEach-Object { Write-Output "  $_" }
  foreach ($f in $filesAll) {
    try {
      (Get-Content -LiteralPath $f -Raw) -replace 'ldt21','Mew36' | Set-Content -LiteralPath $f -Encoding UTF8
      Write-Output "Updated display-case in $f"
    } catch {
      Write-Output "Failed to update (skip): $f - $_"
    }
  }
} else {
  Write-Output "`nNo case-insensitive ldt21 matches found."
}

# 5) Show final checks
Write-Output "`n--- final checks ---`n"
Write-Output "Remaining (case-insensitive) occurrences:"
$remaining = Get-GitGrepFiles -pattern "ldt21" -ignoreCase
if ($remaining.Count -eq 0) { Write-Output "  none" } else { $remaining | ForEach-Object { Write-Output "  $_" } }

Write-Output "`nRemaining uppercase occurrences:"
$remainingUpper = Get-GitGrepFiles -pattern "LDT21"
if ($remainingUpper.Count -eq 0) { Write-Output "  none" } else { $remainingUpper | ForEach-Object { Write-Output "  $_" } }

Write-Output "`nGit status (porcelain) and a short summary:"
git status --porcelain=2 --branch
Write-Output "`nYou can now inspect changes with 'git diff' and commit when ready."