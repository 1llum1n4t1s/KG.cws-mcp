# @kagayoi/cws-mcp

[![npm version](https://img.shields.io/npm/v/@kagayoi/cws-mcp)](https://www.npmjs.com/package/@kagayoi/cws-mcp)

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | **한국어** | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

Chrome Web Store 확장 프로그램 관리를 위한 MCP 서버. Claude Code 또는 모든 MCP 클라이언트에서 직접 Chrome 확장 프로그램을 업로드, 게시, 관리할 수 있습니다.

> [mikusnuz/cws-mcp](https://github.com/mikusnuz/cws-mcp)의 포크로, Chrome Web Store **API V2**에 맞게 갱신했습니다: 서비스 계정 인증, 동작하는 OAuth 플로우(Google이 기존 `oob` 플로우를 제거함), 최신 MCP SDK.

## 사용 시기

다음과 같은 경우에 이 MCP를 사용하세요:

- **"내 Chrome 확장 프로그램의 새 버전을 업로드해줘"** — ZIP을 빌드한 뒤 `upload` 도구로 초안으로 푸시
- **"내 확장 프로그램을 Chrome Web Store에 게시해줘"** — `publish`로 심사에 제출하고 공개
- **"내 확장 프로그램의 심사 상태를 확인해줘"** — `status`로 심사 상태, 버전, 배포 비율 확인
- **"업로드와 게시를 한 번에 해줘"** — `submit`으로 upload → publish → status를 단일 호출로 실행
- **"대기 중인 제출을 취소해줘"** — `cancel`로 심사 중인 제출 철회
- **"내 확장 프로그램에 단계적 배포를 설정해줘"** — `deployPercentage`와 함께 `publish`를 사용한 뒤 `deploy-percentage`로 비율을 높임
- **"새 릴리스에 문제가 있어, 롤백해줘"** — `rollback` 사용 (먼저 `validateOnly=true`로 검증)
- **"최근 리뷰와 평점을 보여줘"** — `reviews`와 `rating-summary` 사용
- **"지난달 설치 수와 활성 사용자 수가 얼마였어?"** — `metrics` 사용

## 도구

| 도구 | 설명 |
|---|---|
| `upload` | ZIP 파일을 Chrome Web Store에 업로드 (기존 항목의 초안 업데이트) |
| `publish` | 선택적 단계적 배포, 게시 유형, 심사 건너뛰기로 확장 프로그램 게시 |
| `status` | 심사 상태, 배포 비율, 버전 등 현재 상태 조회 |
| `cancel` | 대기 중인 제출 취소 |
| `deploy-percentage` | 단계적 배포 비율 설정 (0-100, 현재 목표보다 커야 함) |
| `get`, `update-metadata` | 이전 메타데이터 도구; v1 종료 시점 이후 서버가 차단함 (아래 참고) |
| `submit` | 원샷: upload → publish → status를 단일 호출로 실행 (존재 여부 사전 확인과 읽기 쉬운 오류 포함) |
| `rollback` | 이전에 게시된 버전을 더 높은 새 버전 번호로 재게시 (심사 없음; `validateOnly` 드라이런 지원) |
| `reviews` | 사용자 리뷰를 페이지네이션, 정렬(`rating`, `create_time desc`), 평점 필터와 함께 조회 |
| `rating-summary` | 평균 평점, 평점 수, 별점별 개수 조회 |
| `metrics` | 기간별 설치, 제거, 일간/7일 사용자, 노출, 페이지 조회 수를 조회하며, 선택적으로 하나의 차원으로 분할 |

`reviews`, `rating-summary`, `metrics`는 읽기 전용이며, `https://www.googleapis.com/auth/chromewebstore.readonly` 범위로 제한된 자격 증명도 허용하지만, 서버는 서비스 계정에 대해 전체 `chromewebstore` 범위를 요청합니다.

> Chrome Web Store API로는 항목을 생성할 수 없습니다. Chrome Web Store Developer Dashboard에서 새 항목을 수동으로 만든 뒤, 해당 항목 ID에 대해 `upload` / `publish`(또는 `submit`)를 사용하세요.

## 리스팅 메타데이터

서버 시계가 **2026-10-15 00:00 UTC**를 지나면 서버는 API 요청을 보내기 전에 `get`과 `update-metadata`를 차단합니다. 이 이전 도구들은 탐색 목록에는 계속 표시되지만 종료 시점 이후에는 사용할 수 없습니다. 리스팅 텍스트와 기타 메타데이터는 Chrome Web Store Developer Dashboard에서 수동으로 편집하세요. 이 서버에는 v2 메타데이터 대체 기능이나 브라우저 자동화가 없습니다.

심사 상태, 버전, 배포 정보는 `status`를 사용하세요. 프롬프트는 리스팅 메타데이터 작업을 Developer Dashboard로 안내합니다. `cws://extensions/{extensionId}` 리소스는 종료 시점 이후에도 v2 상태를 반환하고, v1 요청을 건너뛰며, `metadata.unavailable`을 보고합니다.

## 설정

아래 `npx` 예제를 사용하려면 Node.js **20 이상**을 설치하세요. 또는 Bun을 설치하고 `"command": "npx"`와 `"args": ["--yes", "@kagayoi/cws-mcp@latest"]`를 `"command": "bunx"`와 `"args": ["--bun", "@kagayoi/cws-mcp@latest"]`로 바꾸면(`bunx --bun @kagayoi/cws-mcp@latest`를 실행하는 것과 동일) Node.js 없이 실행할 수 있습니다. 어느 쪽도 전역 패키지 설치가 필요하지 않습니다. `@latest`를 사용하면 실행할 때마다 최신 npm 릴리스가 실행됩니다.

이미 버전을 고정(예: `@kagayoi/cws-mcp@2.0.10`)했거나 버전 없이(`@kagayoi/cws-mcp`) 서버를 등록했다면, 해당 등록의 패키지 인수를 `@kagayoi/cws-mcp@latest`로 변경하세요. 이 README를 갱신해도 기존 등록은 바뀌지 않지만, 변경한 뒤에는 실행할 때마다 자동으로 최신 릴리스를 사용합니다.

**서비스 계정**(권장, CI/CD에 적합) **또는** OAuth2 refresh token 중 하나로 인증하세요.

### 옵션 A — 서비스 계정 (권장)

1. [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트를 생성/선택하고 **Chrome Web Store API**를 활성화합니다.
2. **서비스 계정**을 만든 다음 **JSON 키**를 추가합니다 (Keys → Add key → Create new key → JSON).
3. [Developer Dashboard](https://chrome.google.com/webstore/devconsole) → **Account**에서 서비스 계정의 이메일을 추가하여 퍼블리셔 계정에 대한 API 접근 권한을 부여합니다.
4. `CWS_SERVICE_ACCOUNT_KEY`를 **JSON 키 파일의 경로**(또는 JSON 원문)로 설정합니다.

자세한 내용은 [Use a service account with the Chrome Web Store API](https://developer.chrome.com/docs/webstore/service-accounts)를 참고하세요.

### 옵션 B — OAuth2 Refresh Token

1. [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트를 생성/선택하고 **Chrome Web Store API**를 활성화합니다.
2. **데스크톱 앱** 유형의 **OAuth2 자격 증명**을 만듭니다. **Client ID**와 **Client Secret**을 기록해 둡니다.
3. **loopback 리디렉션**으로 refresh token을 발급받습니다. (기존 `urn:ietf:wg:oauth:2.0:oob` 플로우는 2022년에 Google이 제거하여 더 이상 동작하지 않습니다 — 데스크톱 클라이언트는 이제 `http://localhost`를 사용합니다.)

   ```bash
   # 1. Open this URL in a browser and grant access:
   #    https://accounts.google.com/o/oauth2/v2/auth?response_type=code&access_type=offline&prompt=consent&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fchromewebstore&client_id=YOUR_CLIENT_ID&redirect_uri=http://localhost:8080
   #
   # 2. The browser is redirected to http://localhost:8080/?code=AUTH_CODE&...
   #    (no server needed — just copy the `code` value from the address bar).
   #
   # 3. Exchange the code for a refresh token:
   curl -X POST https://oauth2.googleapis.com/token \
     -d "client_id=YOUR_CLIENT_ID" \
     -d "client_secret=YOUR_CLIENT_SECRET" \
     -d "code=YOUR_AUTH_CODE" \
     -d "grant_type=authorization_code" \
     -d "redirect_uri=http://localhost:8080"
   ```

   응답에 `refresh_token`이 포함됩니다. 데스크톱 앱 클라이언트는 `http://localhost[:PORT]` 또는 `http://127.0.0.1[:PORT]` 리디렉션을 모두 허용합니다.

### MCP 설정

다음 서버 정의를 MCP 클라이언트의 설정에 추가하세요. 예제는 `mcpServers` 형식을 사용합니다. 클라이언트 문서에 안내된 설정 위치나 서버 추가 명령을 사용하세요.

**npm + 서비스 계정 (권장):**

```json
{
  "mcpServers": {
    "cws-mcp": {
      "command": "npx",
      "args": ["--yes", "@kagayoi/cws-mcp@latest"],
      "env": {
        "CWS_SERVICE_ACCOUNT_KEY": "/path/to/service-account.json",
        "CWS_PUBLISHER_ID": "me",
        "CWS_ITEM_ID": "your-extension-id"
      }
    }
  }
}
```

**npm + OAuth refresh token:**

```json
{
  "mcpServers": {
    "cws-mcp": {
      "command": "npx",
      "args": ["--yes", "@kagayoi/cws-mcp@latest"],
      "env": {
        "CWS_CLIENT_ID": "xxxxx.apps.googleusercontent.com",
        "CWS_CLIENT_SECRET": "GOCSPX-xxxxx",
        "CWS_REFRESH_TOKEN": "1//xxxxx",
        "CWS_PUBLISHER_ID": "me",
        "CWS_ITEM_ID": "your-extension-id"
      }
    }
  }
}
```

## 환경 변수

서비스 계정 키(인증 A) **또는** OAuth2 refresh token 3종(인증 B) 중 하나를 제공하세요.

| 변수 | 필수 | 설명 |
|---|---|---|
| `CWS_SERVICE_ACCOUNT_KEY` | 인증 A | 서비스 계정 JSON 키 파일 경로 또는 JSON 원문. 설정되어 있으면 OAuth보다 우선합니다. |
| `CWS_CLIENT_ID` | 인증 B | Google OAuth2 Client ID |
| `CWS_CLIENT_SECRET` | 인증 B | Google OAuth2 Client Secret |
| `CWS_REFRESH_TOKEN` | 인증 B | OAuth2 Refresh Token |
| `CWS_PUBLISHER_ID` | 아니오 | 퍼블리셔 ID (기본값: `me`) |
| `CWS_ITEM_ID` | 아니오 | 기본 확장 프로그램 항목 ID |

## 사용 예시

### 확장 프로그램 상태 확인
```
Use the cws-mcp status tool
```

응답에는 원본 API 상태와 최선의 요약이 포함됩니다. 해당 정보가 있으면 게시된 리비전과 제출된 리비전이 따로 표시되며, 각 릴리스 채널의 버전과 배포 비율도 함께 표시됩니다. 제공되는 경우 삭제(takedown) 및 경고 플래그와 마지막 비동기 업로드 상태도 표시됩니다. 추출된 문제가 없는 요약이 승인을 의미하는 것은 아니므로, 자세한 내용은 원본 응답을 확인하세요. 활성 상태의 삭제나 경고가 있으면 Developer Dashboard를 확인해야 합니다.

### 업로드 후 게시
```
1. Use cws-mcp upload with zipPath="/path/to/extension.zip"
2. Use cws-mcp publish
```

### 초기 배포 비율을 지정하여 게시
```
Use cws-mcp publish with:
- deployPercentage=10
```

`publishType="STAGED_PUBLISH"`는 대신 승인된 버전을 수동 게시 대기 상태로 두며, 배포 비율 자체를 설정하지는 않습니다. 기본 게시 유형은 승인 후 게시합니다. `skipReview=true`는 자격이 되는 경우에만 심사 건너뛰기를 시도합니다.

### 심사 건너뛰기로 게시
```
Use cws-mcp publish with skipReview=true
```

### 단계적 배포
```
1. Use cws-mcp publish with deployPercentage=10
2. After approval and publication, check the current target with cws-mcp status
3. Use cws-mcp deploy-percentage with percentage=50
4. Use cws-mcp deploy-percentage with percentage=100
```

참고: `deploy-percentage`는 7일 활성 사용자가 10,000명 이상인 확장 프로그램에서만 사용할 수 있습니다. 새 비율은 항상 현재 목표보다 높아야 합니다.

### 문제 있는 릴리스 롤백
```
1. Use cws-mcp rollback with newVersion="1.2.1", rollbackReason="crash on startup", validateOnly=true
2. If validation succeeds, run the same call without validateOnly
3. Use cws-mcp status to confirm the published revision
```

롤백은 심사 없이 약 1분 내에 모든 사용자에게 적용됩니다. 대기 중이거나 스테이징된 제출은 폐기되며, 비율 배포 중에는 100%로 배포되었던 마지막 버전으로 되돌립니다. `newVersion`은 현재 게시된 버전보다 높아야 합니다. 롤백을 반복하면 같은 두 버전 사이를 오가게 되므로, 이전 버전이 새 버전이 기록한 데이터를 처리할 수 있는지 확인하세요.

### 리뷰, 평점, 지표
```
Use cws-mcp reviews with orderBy="create_time desc", pageSize=20
Use cws-mcp reviews with filter="rating = 1"
Use cws-mcp rating-summary
Use cws-mcp metrics with metrics=["installs","users-7d"], firstDate="2026-10-01", lastDate="2026-10-31", dimension="country"
```

`metrics`는 최대 하나의 차원만 허용합니다. 결과는 페이지로 나뉩니다. 반환된 `nextPageToken`을 `pageToken`으로 전달하고 나머지 매개변수는 동일하게 유지하세요.

## 문제 해결

- **자격 증명 누락 / 401 / 403:** 서버 프로세스의 환경과 항목/퍼블리셔 접근 권한을 확인하세요. 설정된 서비스 계정 키가 우선하며, 유효하지 않은 서비스 계정 자격 증명이라도 OAuth로 폴백하지 않습니다.
- **항목 누락 / 404:** 먼저 Developer Dashboard에서 항목을 생성한 다음 `itemId`를 전달하거나 `CWS_ITEM_ID`를 설정하세요. 모든 항목을 나열하는 도구는 없습니다.
- **ZIP을 읽을 수 없음:** `zipPath`는 MCP 서버를 실행하는 머신(해당되는 경우 컨테이너 내부 포함)에서 접근 가능한 파일을 가리켜야 합니다. `upload` 또는 `submit`을 호출하기 전에 ZIP을 빌드하세요.
- **업로드가 아직 처리 중이거나 완료 여부를 알 수 없음:** `upload`와 `submit`은 업로드 성공이 확인된 경우에만 성공을 보고합니다. 그렇지 않으면 `submit`은 게시 전에 중단하며, 두 도구 모두 자동으로 폴링하지 않습니다. 처리가 계속 진행 중일 수 있는 동안에는 다시 업로드하거나 `submit`을 반복하지 마세요. `status`로 `lastAsyncUploadState`를 확인한 뒤, 의도한 ZIP의 성공을 확인한 경우에만 `publish`를 단독으로 사용하세요. 이 상태는 24시간 이내의 최근 비동기 업로드를 나타내므로, 다른 업로드가 있었거나 상태가 없거나 불명확한 경우에는 먼저 Developer Dashboard에서 초안을 확인하세요.
- **이미 심사 중 / 중복 버전:** 심사를 기다리거나 업로드 전에 `cancel`을 사용하세요. 중복 버전이라면 확장 프로그램의 `manifest.json` 버전을 올리고 ZIP을 다시 빌드하세요.
- **업로드 상태 `NOT_FOUND`:** 업로드 실패로 처리되며 게시는 시도되지 않습니다. 항목 ID를 다시 확인하고 다시 업로드하세요.
- **업로드는 성공했지만 게시 실패:** HTTP 오류라면 `publish`만 다시 시도하세요. 게시 요청이 타임아웃되었거나 연결이 실패했다면 게시 결과를 알 수 없으므로 먼저 `status`를 확인하세요. `submit`을 다시 실행하면 ZIP을 다시 업로드합니다. `submit`은 통신 오류 시 완료된 단계를 유지하고 즉시 상태 스냅샷을 반환하며, 심사 완료를 기다리지 않습니다. 마지막 status 단계가 실패했다면 `status`를 다시 확인하고, 요약에 추출된 문제가 없는 경우에는 원본 응답을 확인하세요.
- **이전 메타데이터 오류:** [리스팅 메타데이터](#리스팅-메타데이터)에 설명된 대로 Developer Dashboard를 사용하세요.

## 개발

로컬 빌드 명령과 검증은 [AGENTS.md](AGENTS.md)를 참고하세요. 구성 요소 경계, API 매핑, 제출 실패 동작은 [DESIGN.md](DESIGN.md)를 참고하세요.

## 라이선스

MIT
