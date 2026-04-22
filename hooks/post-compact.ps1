# PostCompact hook — re-inject critical context after context compaction

$RepoRoot = Split-Path -Parent $PSScriptRoot
$HuskyMemory = if ($env:HUSKY_MEMORY_DIR) { $env:HUSKY_MEMORY_DIR } else { "$env:USERPROFILE\Documents\Husky_Memory" }
$SessionDir = "$HuskyMemory\session_notes\husky"
$MemoryDir = "$RepoRoot\.claude\memory"

Write-Output "=== [Husky PostCompact Recovery] ==="
Write-Output ""

# 1. Core persona
Write-Output "## Core Persona"
Write-Output ""
Get-Content "$RepoRoot\CLAUDE.md"
Write-Output ""

# 2. Checkpoint (working state)
$checkpointPaths = @("$HuskyMemory\checkpoint.md", "$MemoryDir\checkpoint.md")
foreach ($cp in $checkpointPaths) {
    if (Test-Path $cp) {
        Write-Output "## Checkpoint (recovered --- act on this IMMEDIATELY)"
        Write-Output ""
        Get-Content $cp
        Write-Output ""
        Remove-Item $cp
        break
    }
}

# 3. Session notes (today)
$today = Get-Date -Format "yyyy-MM-dd"
$todayFile = "$SessionDir\$today.md"
if (Test-Path $todayFile) {
    Write-Output "## Session Notes ($today)"
    Write-Output ""
    Get-Content $todayFile
    Write-Output ""
}

# 4. Memory index
if (Test-Path "$MemoryDir\MEMORY.md") {
    Write-Output "## Memory Index"
    Write-Output ""
    Get-Content "$MemoryDir\MEMORY.md"
    Write-Output ""
}

# 5. Unanswered-Discord safety net
Write-Output "## Unanswered Reply Check (CRITICAL)"
Write-Output ""
Write-Output "Compact replaces original Discord user blocks with summary text. The Stop hook only sees"
Write-Output "post-compact Discord messages, so pre-compact 미답변 메시지를 놓친다."
Write-Output ""
Write-Output "Inspect the summary above. If a user 요청이 reply/dismiss tool 호출 없이 남아있다면:"
Write-Output "  1. mcp__husky__reply 또는 mcp__husky__dismiss 로 지금 즉시 처리하라."
Write-Output "  2. 이미 처리됐다고 확신하면 무시."
Write-Output ""
Write-Output "Default assumption: 미답변이 있다고 보고 summary 를 재검토할 것."
Write-Output ""
Write-Output "=== [PostCompact Recovery Complete] ==="
