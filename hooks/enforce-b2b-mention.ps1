# PreToolUse hook — inject B2B mention reminder whenever mcp__husky__reply is called.
# KNOWN_BOTS 는 설치 시 페르소나/환경에 맞게 채운다. 비어있으면 조용히 통과.

$Input = [Console]::In.ReadToEnd()

try {
    $payload = $Input | ConvertFrom-Json
} catch {
    exit 0
}

if ($payload.tool_name -ne "mcp__husky__reply") { exit 0 }

$text = ""
$channelId = ""
if ($payload.tool_input) {
    if ($payload.tool_input.text) { $text = [string]$payload.tool_input.text }
    if ($payload.tool_input.channelId) { $channelId = [string]$payload.tool_input.channelId }
}

$mentions = [regex]::Matches($text, '<@!?(\d{17,20})>') | ForEach-Object { $_.Groups[1].Value }

# 다른 봇과의 relay 구성 시 여기를 채운다 (Discord user ID)
$KnownBots = @{
    # "000000000000000000" = "ExampleBot"
}

if ($KnownBots.Count -eq 0) { exit 0 }

$mentionedBots = @()
$missingBotIds = @()
foreach ($uid in $KnownBots.Keys) {
    if ($mentions -contains $uid) {
        $mentionedBots += $KnownBots[$uid]
    } else {
        $missingBotIds += "$($KnownBots[$uid]): <@$uid>"
    }
}

$lines = @(
    "B2B 멘션 체크 리마인더 (mcp__husky__reply 호출 감지)",
    "",
    "현재 대화 상대가 다른 봇이라면 반드시 그 봇의 `<@봇ID>` 멘션이 text 에 포함돼야 메시지가 전달된다.",
    "인간 대상 DM/채널이면 멘션 불필요 — 판단은 대화 맥락으로.",
    "",
    "- channelId: $channelId"
)
if ($mentions.Count -gt 0) {
    $lines += "- text 내 발견된 멘션: $($mentions -join ', ')"
} else {
    $lines += "- text 내 발견된 멘션: 없음"
}
if ($mentionedBots.Count -gt 0) { $lines += "- 포함된 알려진 봇: $($mentionedBots -join ', ')" }
if ($missingBotIds.Count -gt 0) {
    $lines += "- 아직 멘션 안 된 알려진 봇: $($missingBotIds -join ', ')"
} else {
    $lines += "- 아직 멘션 안 된 알려진 봇: 없음"
}
$lines += ""
$lines += "이 reply 의 의도된 수신자가 위 '아직 멘션 안 된 봇' 중에 있는데 멘션을 빠트렸다면, 지금 즉시 reply tool 을 재호출해 해당 `<@봇ID>` 를 text 에 포함해 다시 보낼 것. 인간만 대상이거나 이미 올바른 봇이 멘션되어 있으면 추가 액션 불필요."

$reminder = $lines -join "`n"

$out = @{
    hookSpecificOutput = @{
        hookEventName = "PreToolUse"
        permissionDecision = "allow"
        additionalContext = $reminder
    }
} | ConvertTo-Json -Depth 5 -Compress

Write-Output $out
