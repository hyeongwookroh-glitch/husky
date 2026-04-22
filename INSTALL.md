# Husky Installation — Agent Instructions

이 파일은 **Claude Code 에이전트가 읽고 그대로 수행하는 설치 스크립트**다. 유저가 "설치 진행해줘" 또는 `/install` 슬래시 커맨드 호출 시 이 순서대로 실행한다.

## 목적

아직 설정이 안 된 Husky 디렉토리를 working state 로 끌어올린다. 완료 마커는 `.claude/setup-complete`.

## 중단 조건

- 이미 `.claude/setup-complete` 존재 → "이미 설치됨. 재설치하려면 `rm .claude/setup-complete CLAUDE.md .claude/settings.json .env` 후 다시 호출하라" 라고 답하고 중단.

## 스텝 (순서대로, 병렬 금지)

### 1. OS 감지

- `process.platform === 'win32'` → `windows`
- 그 외 → `macos` (Linux 포함, hook 스크립트 동일)

### 2. 전제조건 체크 (Bash `command -v` 또는 Windows `where`)

- `node` (v22+ 권장, 버전 체크는 경고만)
- `npm`
- `claude` (로그인 여부는 체크 불가, 안내만)
- macOS/Linux: `expect` (`brew install expect` / `apt-get install expect` 안내)

누락이 있으면 목록 제시하고 **설치를 중단하고 유저에게 설치 후 재호출 요청**.

### 3. Channel 의존성 설치

```
cd channels && npm install
```

`channels/node_modules` 이미 존재하면 skip.

### 4. `.claude/settings.json` 생성

- `windows` → `.claude/settings.windows.json` 을 `.claude/settings.json` 으로 복사
- `macos` → `.claude/settings.macos.json` 을 `.claude/settings.json` 으로 복사

### 5. `.env` 준비

`.env` 이미 존재하면 skip, 아니면 이 포맷 템플릿 생성:
```
DISCORD_BOT_TOKEN=
DISCORD_HOME_CHANNEL=
```

그런 다음 유저에게 **별도 메시지로** 다음을 요청:

> Discord Bot 토큰과 Home Channel ID 를 주세요. 한 번에 같이 보내도 됩니다. (Home Channel 은 봇이 멘션 없이 듣는 채널 — DM 위주면 비워도 OK)

유저가 응답하면 파싱해서 `.env` 에 주입. 토큰 포맷 검증은 길이·prefix 만 가볍게 (Discord 토큰은 보통 `Mz...` 또는 `MT...` 로 시작).

### 6. 페르소나 인터뷰

아래 6 질문을 **한 번에 한 문항씩** 유저에게 CLI 로 물어본다. 답이 공란이면 재질문.

1. **Persona name** — 어시스턴트 호칭 (예: Husky, Rex, Aria)
2. **Persona tagline** — 한 줄 역할 설명 (예: "Personal Research Assistant")
3. **Persona role** — 2-3 문장, 전문 분야·유저 맥락·주된 조력 범위
4. **Tone language** — 답변 기본 언어 (기본값: "Korean. Technical terms in English as-is.")
5. **Honorific style** — "반말" / "존댓말" / 기타
6. **Domain capabilities** — 도메인 스킬 2-5개 bullet, 또는 "없음"

### 7. `CLAUDE.md` 렌더

`CLAUDE.md.template` 읽고 placeholder 치환:
- `{{PERSONA_NAME}}` → 답 1
- `{{PERSONA_TAGLINE}}` → 답 2
- `{{PERSONA_ROLE}}` → 답 3
- `{{TONE_LANGUAGE}}` → 답 4
- `{{TONE_HONORIFICS}}` → 답 5
- `{{DOMAIN_CAPABILITIES}}` → 답 6 (markdown bullets, "없음"이면 "Domain-Specific" 섹션 전체 삭제)

결과를 `CLAUDE.md` 에 덮어쓴다.

### 8. `channels/husky-discord.mjs` 페르소나 반영

`agentName` 과 instructions 첫 줄 "You are Husky …" 를 답 1 의 persona name 으로 바꾼다.

### 9. Skills 설치 안내

slash command 는 에이전트가 직접 실행 불가. 유저에게 **설치 완료 후 첫 `run-husky` 실행 시 아래 A 를 세션 안에서 실행**하고, **B 는 터미널에서 별도 실행**하라고 안내.

**A. 문서 스킬 (공식 플러그인 번들)** — docx/xlsx/pptx/pdf
```
/plugin marketplace add anthropics/skills
/plugin install document-skills@anthropics-skills
```

**B. 디자인 스킬 (수동 링크)** — algorithmic-art / brand-guidelines / canvas-design / theme-factory

공식 레포에서 `example-skills` 번들에 묶여 있으나 필요한 것만 개별 링크 가능. 허스키 프로젝트 루트에서:

macOS/Linux:
```bash
mkdir -p .claude/skills && cd .claude/skills
git clone --depth 1 https://github.com/anthropics/skills.git _anthropic-skills
for s in algorithmic-art brand-guidelines canvas-design theme-factory; do
  ln -s "_anthropic-skills/skills/$s" "$s"
done
```

Windows PowerShell (symlink 권한 필요 — Developer Mode 또는 관리자 권한; 안 되면 `Copy-Item -Recurse` 로 복사):
```powershell
New-Item -ItemType Directory -Force .claude\skills | Out-Null
cd .claude\skills
git clone --depth 1 https://github.com/anthropics/skills.git _anthropic-skills
foreach ($s in 'algorithmic-art','brand-guidelines','canvas-design','theme-factory') {
  New-Item -ItemType SymbolicLink -Path $s -Target "_anthropic-skills\skills\$s" | Out-Null
}
```

추가 스킬이 필요하면 (`webapp-testing`, `mcp-builder`, `frontend-design` 등) 위 for 루프에 이름만 추가.

### 10. 완료 마커 + 요약

- `.claude/setup-complete` 파일 생성 (빈 파일)
- 최종 요약 출력:
  - 페르소나 이름
  - `.env` 토큰 입력 여부
  - 다음 실행: macOS `./run-husky.sh` / Windows `run-husky.bat`
  - 문서 스킬 플러그인 설치 안내 (위 9-A)
  - 디자인 스킬 수동 링크 안내 (위 9-B)

### 11. 종료

MCP 툴 호출 금지 (설치 세션은 Husky 가 아직 시동되지 않은 상태). 요약 메시지만 CLI 로 출력하고 유저 다음 입력 대기.

## 규칙

- 에러 발생 시 스텝 번호·원인·복구 방법 명시 후 중단. 무리하게 다음 스텝으로 넘어가지 않는다.
- 유저 답변이 "skip" / "건너뛰기" 면 해당 스텝에 한해 기본값 적용.
- Husky 프로젝트 디렉토리 밖의 파일은 절대 건드리지 않는다.
- 완료까지 단일 turn 안에서 끝나지 않을 수 있음 (유저 입력 대기 지점 다수). 그때마다 재진입 가능하도록 이전 상태 (setup-complete 마커, `.env` 존재, `CLAUDE.md` 존재) 를 체크하며 진행.
