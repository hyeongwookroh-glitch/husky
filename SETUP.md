# Husky Setup — Discord Bot Prep + Troubleshooting

설치 자체는 Claude Code 에이전트가 대화형으로 끌고 간다 (`claude` 실행 → "설치 진행해줘" 또는 `/install`). 이 문서는 **설치 전에 유저가 직접 해야 할 외부 준비**와 **Troubleshooting** 만 다룬다.

## 전제조건

1. **Claude Code CLI** — https://claude.com/claude-code, 로그인 완료
2. **Node.js 22+**
3. **macOS/Linux**: `expect` — `brew install expect` / `apt-get install expect`
4. **Discord Bot** (아래 절차)

## Discord Bot 생성

### 1. Application + Bot 토큰
1. https://discord.com/developers/applications → "New Application" → 이름 아무거나
2. 좌측 "Bot" → "Reset Token" → 복사. → `DISCORD_BOT_TOKEN`

### 2. Privileged Gateway Intents
Bot 페이지에서 **3개 모두** 활성화:
- Presence Intent
- Server Members Intent
- **Message Content Intent** (필수 — 꺼져 있으면 메시지 수신 불가)

### 3. 서버 초대
1. "OAuth2" → "URL Generator"
2. Scopes: `bot`
3. Bot Permissions: `Send Messages`, `Read Message History`, `Add Reactions`, `Attach Files`, `View Channels`
4. 생성된 URL 브라우저에서 열기 → 서버 선택 → 초대

### 4. Home Channel ID
1. Discord 설정 → Advanced → "Developer Mode" 활성화
2. 봇이 기본 대응할 채널 우클릭 → "Copy Channel ID" → `DISCORD_HOME_CHANNEL`

> Home channel 은 봇이 멘션 없이도 듣는 채널. DM 위주면 공란 허용.

## 설치 실행

```bash
git clone <repo-url> husky
cd husky
claude
```

Claude 세션 안에서:
```
설치 진행해줘
```
또는:
```
/install
```

에이전트가 순차적으로:
1. OS 감지 → `.claude/settings.json` 생성 (macOS 는 bash hook, Windows 는 ps1 hook)
2. `channels/` npm install
3. Discord 토큰/채널 ID 요청 (별도 턴, 복붙)
4. 페르소나 6문 인터뷰 → `CLAUDE.md` 생성
5. `.claude/setup-complete` 마커 + 다음 실행 안내

완료 후 설치 세션 종료 (`/exit`).

## 첫 실행

```bash
./run-husky.sh      # macOS / Linux
run-husky.bat       # Windows
```

세션 안에서 **한 번만**:
```
/plugin marketplace add anthropics/skills
/plugin install document-skills@anthropics-skills
```
→ docx / xlsx / pptx / pdf 스킬 활성.

## 메모리 디렉토리 오버라이드

기본 외 경로면 `.env` 에 추가:
```
HUSKY_MEMORY_DIR=/path/to/wherever
```

(hook 이 우선 사용, 없으면 `~/Documents/Husky_Memory`)

## 재설치 / 페르소나 교체

```bash
rm .claude/setup-complete CLAUDE.md .claude/settings.json .env
claude
> 설치 진행해줘
```

## Troubleshooting

| 증상 | 원인 | 해결 |
|------|------|------|
| `command not found: expect` | macOS/Linux 의존성 | `brew install expect` / `apt-get install expect` |
| Discord 연결 안됨 | 토큰 오류 | `.env` 재확인 |
| 메시지 수신 안됨 | Message Content Intent 꺼짐 | Developer Portal → Bot → 인텐트 활성화 |
| 설치 에이전트가 MCP 툴 호출 시도 | `CLAUDE.md` stub 지시 무시 | 설치 중에는 MCP 호출 금지 — stub 재확인 |
| Windows hook 실행 안됨 | 설치 시 OS 오탐지 | `.claude/settings.json` 지우고 `.claude/settings.windows.json` 복사 |
| `/plugin install` 실패 | 마켓플레이스 미등록 | `/plugin marketplace add anthropics/skills` 먼저 |
| "이미 설치됨" 으로 재실행 안됨 | `.claude/setup-complete` 존재 | 위 "재설치" 섹션 참고 |
