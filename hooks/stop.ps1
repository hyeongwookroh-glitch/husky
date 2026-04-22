# Stop hook — mark session end in today's notes

$HuskyMemory = if ($env:HUSKY_MEMORY_DIR) { $env:HUSKY_MEMORY_DIR } else { "$env:USERPROFILE\Documents\Husky_Memory" }
$SessionDir = "$HuskyMemory\session_notes\husky"
$today = Get-Date -Format "yyyy-MM-dd"
$SessionFile = "$SessionDir\$today.md"

if (Test-Path $SessionFile) {
    $now = Get-Date -Format "HH:mm"
    Add-Content $SessionFile ""
    Add-Content $SessionFile "---"
    Add-Content $SessionFile "_Session ended: ${now}_"
}
