# @kagayoi/cws-mcp

[![npm version](https://img.shields.io/npm/v/@kagayoi/cws-mcp)](https://www.npmjs.com/package/@kagayoi/cws-mcp)

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | **繁體中文** | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

用於管理 Chrome Web Store 擴充功能的 MCP 伺服器。可直接從 Claude Code 或任何 MCP 用戶端上傳、發布及管理 Chrome 擴充功能。

> [mikusnuz/cws-mcp](https://github.com/mikusnuz/cws-mcp) 的分支，已更新以支援 Chrome Web Store **API V2**：服務帳戶驗證、可正常運作的 OAuth 流程（Google 已移除舊的 `oob` 流程），以及最新的 MCP SDK。

## 使用時機

在以下情況可使用此 MCP：

- **「上傳我的 Chrome 擴充功能的新版本」** — 建置 ZIP 後，使用 `upload` 工具將其推送為草稿
- **「將我的擴充功能發布到 Chrome Web Store」** — 使用 `publish` 提交審查並上線
- **「檢查我的擴充功能的審查狀態」** — 使用 `status` 查看審查狀態、版本與部署百分比
- **「一個步驟完成上傳與發布」** — 使用 `submit`，以單一呼叫執行 upload → publish → status
- **「取消待處理的提交」** — 使用 `cancel` 撤回審查中的提交
- **「為我的擴充功能設定分階段推出」** — 使用帶有 `deployPercentage` 的 `publish`，再用 `deploy-percentage` 逐步提高
- **「新版本有問題，請回復」** — 使用 `rollback`（先以 `validateOnly=true` 驗證）
- **「顯示我最新的評論／評分」** — 使用 `reviews` 與 `rating-summary`
- **「上個月有多少安裝數與活躍使用者？」** — 使用 `metrics`

## 工具

| 工具 | 說明 |
|---|---|
| `upload` | 將 ZIP 檔案上傳至 Chrome Web Store（更新現有項目的草稿） |
| `publish` | 發布擴充功能，可選擇分階段推出、發布類型及略過審查 |
| `status` | 取得目前狀態，包括審查狀態、部署百分比與版本 |
| `cancel` | 取消待處理的提交 |
| `deploy-percentage` | 設定分階段推出百分比（0-100，必須高於目前目標） |
| `get`, `update-metadata` | 舊版中繼資料工具；伺服器在 v1 截止日期之後會將其封鎖（見下文） |
| `submit` | 一次完成：以單一呼叫執行 upload → publish → status（含項目存在性預檢與易讀的錯誤訊息） |
| `rollback` | 以更高的新版本號重新發布先前已發布的版本（無需審查；支援 `validateOnly` 試執行） |
| `reviews` | 取得使用者評論，支援分頁、排序（`rating`、`create_time desc`）與評分篩選 |
| `rating-summary` | 取得平均評分、評分數量及各星級數量 |
| `metrics` | 查詢指定日期範圍內的安裝、解除安裝、每日／7 日使用者、曝光次數與頁面瀏覽次數，可選擇依單一維度切分 |

`reviews`、`rating-summary` 與 `metrics` 為唯讀；它們也接受僅限於 `https://www.googleapis.com/auth/chromewebstore.readonly` 範圍的憑證，但伺服器會為服務帳戶要求完整的 `chromewebstore` 範圍。

> Chrome Web Store API 無法建立項目。請先在 Chrome Web Store Developer Dashboard 中手動建立新項目，再針對其項目 ID 使用 `upload` / `publish`（或 `submit`）。

## 清單中繼資料

當伺服器時鐘晚於 **2026-10-15 00:00 UTC** 時，伺服器會在發出任何 API 請求之前封鎖 `get` 與 `update-metadata`。這些舊版工具仍會顯示在探索清單中，但在截止日期之後無法使用。請在 Chrome Web Store Developer Dashboard 中手動編輯商店清單文字及其他中繼資料；此伺服器沒有 v2 中繼資料替代方案，也沒有瀏覽器自動化。

請使用 `status` 取得審查狀態、版本與推出資訊。提示會將清單中繼資料的工作導向 Developer Dashboard。`cws://extensions/{extensionId}` 資源在截止日期之後仍會傳回 v2 狀態，並略過 v1 請求，同時回報 `metadata.unavailable`。

## 設定

請安裝 Node.js **20 或更新版本**以使用下列 `npx` 範例；或者安裝 Bun，並將 `"command": "npx"` 與 `"args": ["--yes", "@kagayoi/cws-mcp@latest"]` 替換為 `"command": "bunx"` 與 `"args": ["--bun", "@kagayoi/cws-mcp@latest"]`（等同於執行 `bunx --bun @kagayoi/cws-mcp@latest`），即可在沒有 Node.js 的情況下執行。兩種方式都不需要全域安裝套件。使用 `@latest` 時，每次啟動都會執行最新的 npm 版本。

如果您已使用固定版本（例如 `@kagayoi/cws-mcp@2.0.10`）或未指定版本（`@kagayoi/cws-mcp`）註冊了伺服器，請將該註冊中的套件引數改為 `@kagayoi/cws-mcp@latest`；更新此 README 不會變更既有的註冊，但在該修改之後，每次啟動都會自動使用最新版本。

請使用**服務帳戶**（建議，適合 CI/CD）**或** OAuth2 重新整理權杖進行驗證。

### 選項 A — 服務帳戶（建議）

1. 在 [Google Cloud Console](https://console.cloud.google.com/) 中建立／選取專案，並啟用 **Chrome Web Store API**。
2. 建立**服務帳戶**，然後新增 **JSON 金鑰**（Keys → Add key → Create new key → JSON）。
3. 在 [Developer Dashboard](https://chrome.google.com/webstore/devconsole) → **Account** 中，新增該服務帳戶的電子郵件，授予其對您的發布者帳戶的 API 存取權。
4. 將 `CWS_SERVICE_ACCOUNT_KEY` 設為 **JSON 金鑰檔案的路徑**（或其原始 JSON 內容）。

詳情請參閱 [Use a service account with the Chrome Web Store API](https://developer.chrome.com/docs/webstore/service-accounts)。

### 選項 B — OAuth2 重新整理權杖

1. 在 [Google Cloud Console](https://console.cloud.google.com/) 中建立／選取專案，並啟用 **Chrome Web Store API**。
2. 建立類型為**桌面應用程式**的 **OAuth2 憑證**。記下 **Client ID** 與 **Client Secret**。
3. 使用**迴路重新導向**取得重新整理權杖。（舊的 `urn:ietf:wg:oauth:2.0:oob` 流程已於 2022 年被 Google 移除，不再有效 — 桌面用戶端現在使用 `http://localhost`。）

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

   回應中包含您的 `refresh_token`。桌面應用程式用戶端接受任何 `http://localhost[:PORT]` 或 `http://127.0.0.1[:PORT]` 重新導向。

### 設定 MCP

將下列伺服器定義加入您的 MCP 用戶端設定中。範例使用 `mcpServers` 格式；請使用您的用戶端文件所載明的設定位置或新增伺服器的指令。

**透過 npm 使用服務帳戶（建議）：**

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

**透過 npm 使用 OAuth 重新整理權杖：**

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

## 環境變數

請提供服務帳戶金鑰（驗證 A）**或** OAuth2 重新整理權杖三項組（驗證 B）。

| 變數 | 必要 | 說明 |
|---|---|---|
| `CWS_SERVICE_ACCOUNT_KEY` | 驗證 A | 服務帳戶 JSON 金鑰檔案的路徑，或原始 JSON 字串。設定後優先於 OAuth。 |
| `CWS_CLIENT_ID` | 驗證 B | Google OAuth2 Client ID |
| `CWS_CLIENT_SECRET` | 驗證 B | Google OAuth2 Client Secret |
| `CWS_REFRESH_TOKEN` | 驗證 B | OAuth2 重新整理權杖 |
| `CWS_PUBLISHER_ID` | 否 | 發布者 ID（預設：`me`） |
| `CWS_ITEM_ID` | 否 | 預設的擴充功能項目 ID |

## 使用範例

### 檢查擴充功能狀態
```
Use the cws-mcp status tool
```

回應包含原始 API 狀態與盡力而為的摘要。若有相關資料，會分別顯示已發布與已提交的修訂版本，以及各發布管道的版本與推出百分比。若有提供，也會顯示下架與警告旗標，以及最後一次非同步上傳的狀態。未擷取到任何問題的摘要並不代表已通過審核；請查看原始回應以了解詳情。若有進行中的下架或警告，請至 Developer Dashboard 確認。

### 上傳並發布
```
1. Use cws-mcp upload with zipPath="/path/to/extension.zip"
2. Use cws-mcp publish
```

### 以初始推出百分比發布
```
Use cws-mcp publish with:
- deployPercentage=10
```

`publishType="STAGED_PUBLISH"` 則是將已核准的版本設為待手動發布；它本身不會設定推出百分比。預設的發布類型會在核准後發布。`skipReview=true` 僅在符合資格時才會嘗試略過審查。

### 略過審查發布
```
Use cws-mcp publish with skipReview=true
```

### 分階段推出
```
1. Use cws-mcp publish with deployPercentage=10
2. After approval and publication, check the current target with cws-mcp status
3. Use cws-mcp deploy-percentage with percentage=50
4. Use cws-mcp deploy-percentage with percentage=100
```

注意：`deploy-percentage` 僅適用於 7 日活躍使用者達 10,000 人以上的擴充功能。新的百分比必須始終高於目前目標。

### 回復有問題的版本
```
1. Use cws-mcp rollback with newVersion="1.2.1", rollbackReason="crash on startup", validateOnly=true
2. If validation succeeds, run the same call without validateOnly
3. Use cws-mcp status to confirm the published revision
```

回復無需審查，約一分鐘內即會對所有使用者生效。它會捨棄待處理與已暫存的提交；在百分比推出期間，會還原為最後一次以 100% 部署的版本。`newVersion` 必須高於目前已發布的版本。重複回復會在同樣的兩個版本之間循環，因此請確保較舊的版本能夠處理較新版本所寫入的資料。

### 評論、評分與指標
```
Use cws-mcp reviews with orderBy="create_time desc", pageSize=20
Use cws-mcp reviews with filter="rating = 1"
Use cws-mcp rating-summary
Use cws-mcp metrics with metrics=["installs","users-7d"], firstDate="2026-10-01", lastDate="2026-10-31", dimension="country"
```

`metrics` 最多接受一個維度。結果會分頁；請將傳回的 `nextPageToken` 作為 `pageToken` 傳入，其餘參數保持完全相同。

## 疑難排解

- **缺少憑證 / 401 / 403：** 請檢查伺服器程序的環境，以及項目／發布者的存取權。已設定的服務帳戶金鑰優先；無效的服務帳戶憑證不會退回使用 OAuth。
- **缺少項目 / 404：** 請先在 Developer Dashboard 中建立項目，再傳入 `itemId` 或設定 `CWS_ITEM_ID`。沒有列出所有項目的工具。
- **無法讀取 ZIP：** `zipPath` 必須指向執行 MCP 伺服器之機器上可存取的檔案（若適用，包括其容器內部）。請在呼叫 `upload` 或 `submit` 之前先建置 ZIP。
- **上傳仍在處理或完成狀態未知：** `upload` 與 `submit` 僅在確認上傳成功時才回報成功。否則 `submit` 會在發布前停止；兩個工具都不會自動輪詢。在處理可能仍在進行時，請避免再次上傳或重複執行 `submit`。請使用 `status` 檢查 `lastAsyncUploadState`，並且只有在確認預期的 ZIP 已成功之後，才單獨使用 `publish`。此狀態涵蓋 24 小時內最近一次非同步上傳，因此若發生過另一次上傳，或狀態缺失或不明確，請先在 Developer Dashboard 中確認草稿。
- **已在審查中 / 版本重複：** 請等待審查，或在上傳前使用 `cancel`；若版本重複，請提高擴充功能 `manifest.json` 中的版本並重新建置其 ZIP。
- **上傳狀態 `NOT_FOUND`：** 視為上傳失敗；不會嘗試發布。請重新檢查項目 ID 並再次上傳。
- **上傳成功但發布失敗：** 若為 HTTP 錯誤，請單獨重試 `publish`。若發布請求逾時或連線失敗，由於發布結果未知，請先檢查 `status`。重新執行 `submit` 會再次上傳 ZIP。`submit` 在通訊錯誤時會保留已完成的步驟，並傳回即時的狀態快照；它不會等待審查完成。若最後的狀態步驟失敗，請再次檢查 `status`；當摘要未擷取到任何問題時，請查看原始回應。
- **舊版中繼資料錯誤：** 請依 [清單中繼資料](#清單中繼資料) 所述使用 Developer Dashboard。

## 開發

本機建置指令與驗證方式，請參閱 [AGENTS.md](AGENTS.md)。元件邊界、API 對應及提交失敗行為，請參閱 [DESIGN.md](DESIGN.md)。

## 授權

MIT
