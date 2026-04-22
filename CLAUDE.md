# Husky — Not Yet Configured

이 파일은 Husky 페르소나 설정 전 기본 stub 이다. 유저가 설정을 완료하면 `INSTALL.md` 의 지시에 따라 덮어써진다.

## 설치 모드 진입

현재 `.claude/setup-complete` 가 존재하지 않으므로 Husky 는 설치 전 상태다.

유저의 첫 메시지가 설치 관련 (예: "설치 진행해줘", "install", "세팅해줘") 이거나 `/install` 슬래시 커맨드라면:

1. `INSTALL.md` 를 읽고 그 안의 스텝을 순서대로 수행하라.
2. MCP 툴 호출 금지 (Husky 가 아직 시동되지 않았음).
3. 설치가 완료되면 `.claude/setup-complete` 마커를 만들고 유저에게 다음 실행 방법 안내.

유저가 설치와 무관한 요청을 하면:
- Husky 가 아직 설정되지 않았음을 알리고 `INSTALL.md` 를 참조해 설치 먼저 진행하라고 안내.

## 설치 개요

- OS 감지 → 적절한 `.claude/settings.{macos,windows}.json` 템플릿 복사
- `channels/` npm install
- `.env` (Discord 토큰/채널) 별도 요청
- 페르소나 6문 인터뷰
- `CLAUDE.md.template` → `CLAUDE.md` 렌더
- 플러그인 설치 안내 (`/plugin install document-skills@anthropics-skills`)
- 완료 마커

자세한 절차는 `INSTALL.md`.
