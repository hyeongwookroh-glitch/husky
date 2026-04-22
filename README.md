# Husky

Persona-agnostic Claude Code agent scaffold. Discord-first communication, auto-restart wrapper, enforced reply/dismiss, document & browser skills out of the box. 설치는 **Claude Code 에이전트가 대화형으로 진행**한다 — 셸 스크립트 없음.

Patrasche 의 Slack agent 를 Discord/개인용으로 일반화한 버전.

---

## 요구사항

- macOS / Linux / Windows 10+
- [Claude Code CLI](https://claude.com/claude-code) (로그인 완료)
- Node.js 22+
- macOS/Linux: `expect` (`brew install expect` / `apt-get install expect`)
- Discord Bot Token + Home Channel ID (아래 SETUP.md 참고)

## 설치 (3 단계)

```bash
git clone <repo-url> husky
cd husky
claude
```

Claude Code 가 뜨면 말 그대로:

> 설치 진행해줘

또는 슬래시 커맨드:

> /install

에이전트가 `INSTALL.md` 를 따라 다음을 수행:
1. OS 감지 → `.claude/settings.json` 생성 (macOS/Windows 템플릿 중 해당)
2. `channels/` npm install
3. Discord 토큰/채널 요청 (별도 턴, 한 번에 같이 붙여넣기 가능)
4. 페르소나 6문 인터뷰 → `CLAUDE.md` 자동 생성
5. `.claude/setup-complete` 마커 + 실행 방법 안내

완료 후 설치 세션 종료 (`Ctrl+C` 또는 `/exit`).

## 실행

**macOS / Linux:**
```bash
./run-husky.sh
```

**Windows:**
```cmd
run-husky.bat
```

첫 세션에서 한 번만:
```
/plugin marketplace add anthropics/skills
/plugin install document-skills@anthropics-skills
```
→ docx / xlsx / pptx / pdf 읽고 쓰기 스킬 활성.

## 디렉토리 구조

```
husky/
├── CLAUDE.md                   # persona (설치가 덮어씀)
├── CLAUDE.md.template          # persona 템플릿 ({{PLACEHOLDER}} 포함)
├── INSTALL.md                  # 설치 에이전트 지시서
├── README.md / SETUP.md
├── run-husky.{sh,bat}          # auto-restart wrapper
├── .mcp-husky.json             # MCP: husky (Discord) + playwright
├── .env                        # Discord 토큰 (설치 중 생성, gitignored)
├── .claude/
│   ├── commands/install.md     # /install 슬래시 커맨드
│   ├── settings.macos.json     # settings 템플릿 (bash hooks)
│   ├── settings.windows.json   # settings 템플릿 (ps1 hooks)
│   ├── settings.json           # 설치 시 OS 맞게 복사 (gitignored)
│   └── setup-complete          # 설치 완료 마커
├── channels/
│   ├── discord-channel.mjs     # Discord MCP 서버
│   └── husky-discord.mjs       # channel 이름/이모지 (설치가 persona name 반영)
└── hooks/
    ├── session-start.{sh,ps1}
    ├── pre-compact.{sh,ps1}
    ├── post-compact.{sh,ps1}
    ├── stop.{sh,ps1}
    ├── enforce-b2b-mention.{sh,ps1}
    └── enforce-discord-reply.{sh,ps1}
```

## 메모리 위치

기본:
- macOS / Linux: `~/Documents/Husky_Memory/`
- Windows: `%USERPROFILE%\Documents\Husky_Memory\`

`HUSKY_MEMORY_DIR` 환경변수로 오버라이드. 설치 중 별도 값 지정 가능.

```
Husky_Memory/
├── session_notes/husky/
├── inbox/
└── checkpoint.md
```

## MCP / Skills

기본 MCP (`.mcp-husky.json`):
- `husky` — Discord channel (reply / dismiss / restart / send_file)
- `playwright` — `@playwright/mcp@latest` 브라우저 자동화

Skill (첫 실행 시 `/plugin install`):
- `document-skills@anthropics-skills` — docx / xlsx / pptx / pdf

추가 MCP 는 `.mcp-husky.json` 에 직접 등록.

## 편의 기능

- **자동 재시작**: `run-husky.{sh,bat}` 무한 루프. crash / `restart` tool / `/exit` 모두 복구.
- **.env 재로드**: 재시작마다 `.env` 다시 읽음 (restart 후 env 변경 반영).
- **미답변 차단**: Stop hook 이 transcript 스캔 → 미답변 Discord 메시지 있으면 종료 차단.
- **Compact 복구**: PreCompact 에서 checkpoint 강제 / PostCompact 가 페르소나·세션 노트·메모리 인덱스 + 미답변 경고 재주입.
- **B2B 멘션 리마인더**: `mcp__husky__reply` 호출 시 KNOWN_BOTS 기준 멘션 누락 리마인드.

## 재설치 / 페르소나 교체

```bash
rm .claude/setup-complete CLAUDE.md .claude/settings.json .env
claude
> 설치 진행해줘
```

`node_modules` 는 유지.
