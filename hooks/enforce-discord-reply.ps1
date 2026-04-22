# Stop hook — block turn-end if any Discord (husky MCP) message has no subsequent
# mcp__husky__reply / mcp__husky__dismiss tool call before end-of-transcript.

$Input = [Console]::In.ReadToEnd()

try {
    $payload = $Input | ConvertFrom-Json
} catch {
    exit 0
}

$transcriptPath = [string]$payload.transcript_path
$stopActive = $false
if ($payload.stop_hook_active) { $stopActive = [bool]$payload.stop_hook_active }

if ($stopActive) { exit 0 }
if (-not $transcriptPath -or -not (Test-Path $transcriptPath)) { exit 0 }

$lines = Get-Content $transcriptPath -ErrorAction SilentlyContinue
if (-not $lines) { exit 0 }

$channelRe = [regex]'(?s)channel source="husky".*?messageTs="(\d{15,})"'

$discordMsgs = @()  # (idx, ts)
$replyIdxs   = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    try {
        $e = $lines[$i] | ConvertFrom-Json
    } catch { continue }

    $t = $e.type
    $msg = $e.message
    if (-not $msg) { continue }

    if ($t -eq 'user') {
        $content = $msg.content
        $isToolResult = $false
        $text = ""
        if ($content -is [array]) {
            foreach ($b in $content) {
                if ($b -is [pscustomobject] -and $b.type -eq 'tool_result') { $isToolResult = $true; break }
            }
            if ($isToolResult) { continue }
            $text = ($content | ConvertTo-Json -Depth 10 -Compress)
        } else {
            $text = [string]$content
        }
        $m = $channelRe.Match($text)
        if ($m.Success) {
            $discordMsgs += ,@($i, $m.Groups[1].Value)
        }
    }
    elseif ($t -eq 'assistant') {
        foreach ($block in $msg.content) {
            if ($block -is [pscustomobject] -and $block.type -eq 'tool_use' -and
                ($block.name -eq 'mcp__husky__reply' -or $block.name -eq 'mcp__husky__dismiss')) {
                $replyIdxs += $i
                break
            }
        }
    }
}

if ($discordMsgs.Count -eq 0) { exit 0 }

$lastReplyIdx = -1
if ($replyIdxs.Count -gt 0) { $lastReplyIdx = $replyIdxs[-1] }

$unanswered = @()
foreach ($pair in $discordMsgs) {
    if ($pair[0] -gt $lastReplyIdx) { $unanswered += $pair[1] }
}

if ($unanswered.Count -eq 0) { exit 0 }

$shown = $unanswered | Select-Object -First 5
$tail = if ($unanswered.Count -gt 5) { " …" } else { "" }
[Console]::Error.WriteLine("BLOCK: 미답변 Discord 메시지 $($unanswered.Count)건 (messageTs: $($shown -join ', ')$tail). mcp__husky__reply 또는 mcp__husky__dismiss로 처리한 뒤 종료하라.")
exit 2
