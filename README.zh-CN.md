# @kagayoi/cws-mcp

[![npm version](https://img.shields.io/npm/v/@kagayoi/cws-mcp)](https://www.npmjs.com/package/@kagayoi/cws-mcp)

[English](README.md) | [日本語](README.ja.md) | **简体中文** | [繁體中文](README.zh-TW.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

用于管理 Chrome 应用商店扩展程序的 MCP 服务器。可直接在 Claude Code 或任何 MCP 客户端中上传、发布和管理 Chrome 扩展程序。

> 这是 [mikusnuz/cws-mcp](https://github.com/mikusnuz/cws-mcp) 的分支，已更新以支持 Chrome 应用商店 **API V2**：服务账号认证、可用的 OAuth 流程（Google 已移除旧的 `oob` 流程）以及最新的 MCP SDK。

## 使用场景

在以下情况下可以使用此 MCP：

- **“上传我的 Chrome 扩展程序的新版本”** — 构建 ZIP 文件，并使用 `upload` 工具将其作为草稿推送
- **“将我的扩展程序发布到 Chrome 应用商店”** — 使用 `publish` 提交审核并上线
- **“查看我的扩展程序的审核状态”** — 使用 `status` 查看审核状态、版本和部署百分比
- **“一步完成上传和发布”** — 使用 `submit`，在一次调用中依次执行 upload → publish → status
- **“取消待处理的提交”** — 使用 `cancel` 撤回正在审核中的提交
- **“为我的扩展程序设置分阶段发布”** — 使用带 `deployPercentage` 的 `publish`，然后使用 `deploy-percentage` 逐步提高比例
- **“新版本有问题，需要回滚”** — 使用 `rollback`（请先用 `validateOnly=true` 验证）
- **“查看我最新的评价/评分”** — 使用 `reviews` 和 `rating-summary`
- **“上个月我获得了多少安装量和活跃用户？”** — 使用 `metrics`

## 工具

| 工具 | 说明 |
|---|---|
| `upload` | 将 ZIP 文件上传到 Chrome 应用商店（更新现有项目的草稿） |
| `publish` | 发布扩展程序，可选择分阶段发布、发布类型和跳过审核 |
| `status` | 获取当前状态，包括审核状态、部署百分比和版本 |
| `cancel` | 取消待处理的提交 |
| `deploy-percentage` | 设置分阶段发布的百分比（0-100，必须大于当前目标值） |
| `get`, `update-metadata` | 旧版元数据工具；在 v1 截止日期之后会被服务器阻止（见下文） |
| `submit` | 一次性操作：在一次调用中依次执行 upload → publish → status（包含存在性预检和易读的错误信息） |
| `rollback` | 以更高的新版本号重新发布先前已发布的版本（无需审核；支持 `validateOnly` 试运行） |
| `reviews` | 获取用户评价，支持分页、排序（`rating`、`create_time desc`）和评分筛选 |
| `rating-summary` | 获取平均评分、评分数量以及各星级的数量 |
| `metrics` | 查询指定日期范围内的安装量、卸载量、日活/7 日活跃用户、展示次数和页面浏览量，可选按一个维度切分 |

`reviews`、`rating-summary` 和 `metrics` 为只读工具；它们也接受仅限 `https://www.googleapis.com/auth/chromewebstore.readonly` 范围的凭据，但服务器会为服务账号请求完整的 `chromewebstore` 范围。

> Chrome 应用商店 API 无法创建项目。请先在 Chrome 应用商店 Developer Dashboard 中手动创建新项目，然后针对其项目 ID 使用 `upload` / `publish`（或 `submit`）。

## 商店信息元数据

当服务器时钟晚于 **2026-10-15 00:00 UTC** 时，服务器会在发出 API 请求之前阻止 `get` 和 `update-metadata`。这些旧版工具仍会显示在工具发现列表中，但在该截止日期之后无法使用。请在 Chrome 应用商店 Developer Dashboard 中手动编辑商店信息文本和其他元数据；此服务器没有 v2 元数据替代方案，也没有浏览器自动化。

请使用 `status` 查看审核状态、版本和发布进度信息。提示词会将商店信息元数据相关工作引导至 Developer Dashboard。在截止日期之后，`cws://extensions/{extensionId}` 资源仍会返回 v2 状态，跳过 v1 请求，并报告 `metadata.unavailable`。

## 设置

要使用下面的 `npx` 示例，请安装 **20 或更高版本**的 Node.js；或者安装 Bun，并将 `"command": "npx"` 和 `"args": ["--yes", "@kagayoi/cws-mcp@latest"]` 替换为 `"command": "bunx"` 和 `"args": ["--bun", "@kagayoi/cws-mcp@latest"]`（等同于运行 `bunx --bun @kagayoi/cws-mcp@latest`），即可在没有 Node.js 的情况下运行。两种方式都不需要全局安装软件包。使用 `@latest` 时，每次启动都会运行最新的 npm 版本。

如果您已经使用固定版本（例如 `@kagayoi/cws-mcp@2.0.10`）或不带版本（`@kagayoi/cws-mcp`）注册了该服务器，请将该注册中的软件包参数改为 `@kagayoi/cws-mcp@latest`；更新本 README 不会更改已有的注册，但修改之后每次启动都会自动使用最新版本。

认证方式二选一：**服务账号**（推荐，适合 CI/CD）**或** OAuth2 刷新令牌。

### 选项 A — 服务账号（推荐）

1. 在 [Google Cloud Console](https://console.cloud.google.com/) 中创建或选择一个项目，并启用 **Chrome Web Store API**。
2. 创建一个**服务账号**，然后添加一个 **JSON 密钥**（密钥 → 添加密钥 → 创建新密钥 → JSON）。
3. 在 [Developer Dashboard](https://chrome.google.com/webstore/devconsole) → **账号**中，添加该服务账号的电子邮件地址，授予其对您的发布者账号的 API 访问权限。
4. 将 `CWS_SERVICE_ACCOUNT_KEY` 设置为 **JSON 密钥文件的路径**（或其原始 JSON 内容）。

详情请参阅 [Use a service account with the Chrome Web Store API](https://developer.chrome.com/docs/webstore/service-accounts)。

### 选项 B — OAuth2 刷新令牌

1. 在 [Google Cloud Console](https://console.cloud.google.com/) 中创建或选择一个项目，并启用 **Chrome Web Store API**。
2. 创建类型为**桌面应用**的 **OAuth2 凭据**。记下**客户端 ID** 和**客户端密钥**。
3. 使用**环回重定向**获取刷新令牌。（旧的 `urn:ietf:wg:oauth:2.0:oob` 流程已于 2022 年被 Google 移除，不再可用——桌面客户端现在使用 `http://localhost`。）

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

   响应中包含您的 `refresh_token`。对于桌面应用客户端，任何 `http://localhost[:PORT]` 或 `http://127.0.0.1[:PORT]` 重定向都会被接受。

### 配置 MCP

将以下服务器定义添加到您的 MCP 客户端配置中。示例使用 `mcpServers` 格式；请使用您的客户端文档中说明的配置位置或添加服务器的命令。

**通过 npm 使用服务账号（推荐）：**

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

**通过 npm 使用 OAuth 刷新令牌：**

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

## 环境变量

请提供服务账号密钥（认证 A）**或** OAuth2 刷新令牌三件套（认证 B），二者择一。

| 变量 | 是否必需 | 说明 |
|---|---|---|
| `CWS_SERVICE_ACCOUNT_KEY` | 认证 A | 服务账号 JSON 密钥文件的路径，或原始 JSON 字符串。设置后优先于 OAuth。 |
| `CWS_CLIENT_ID` | 认证 B | Google OAuth2 客户端 ID |
| `CWS_CLIENT_SECRET` | 认证 B | Google OAuth2 客户端密钥 |
| `CWS_REFRESH_TOKEN` | 认证 B | OAuth2 刷新令牌 |
| `CWS_PUBLISHER_ID` | 否 | 发布者 ID（默认值：`me`） |
| `CWS_ITEM_ID` | 否 | 默认的扩展程序项目 ID |

## 使用示例

### 查看扩展程序状态
```
Use the cws-mcp status tool
```

响应包含 API 返回的原始状态和尽力而为的摘要。如果存在，已发布和已提交的修订版本会分别显示，并包含各发布渠道的版本和发布百分比。如果有提供，还会显示下架和警告标记以及最近一次异步上传的状态。没有提取到问题的摘要并不能确认已获批准；请查看原始响应了解详情。如果存在生效的下架或警告，需要到 Developer Dashboard 中查看。

### 上传并发布
```
1. Use cws-mcp upload with zipPath="/path/to/extension.zip"
2. Use cws-mcp publish
```

### 以初始发布百分比进行发布
```
Use cws-mcp publish with:
- deployPercentage=10
```

`publishType="STAGED_PUBLISH"` 则会将已批准的版本暂存以便手动发布；它本身不会设置发布百分比。默认的发布类型会在获批后发布。`skipReview=true` 仅在符合条件时才会尝试跳过审核。

### 跳过审核发布
```
Use cws-mcp publish with skipReview=true
```

### 分阶段发布
```
1. Use cws-mcp publish with deployPercentage=10
2. After approval and publication, check the current target with cws-mcp status
3. Use cws-mcp deploy-percentage with percentage=50
4. Use cws-mcp deploy-percentage with percentage=100
```

注意：`deploy-percentage` 仅适用于 7 日活跃用户达到 10,000 以上的扩展程序。新的百分比必须始终高于当前目标值。

### 回滚有问题的版本
```
1. Use cws-mcp rollback with newVersion="1.2.1", rollbackReason="crash on startup", validateOnly=true
2. If validation succeeds, run the same call without validateOnly
3. Use cws-mcp status to confirm the published revision
```

回滚无需审核，约一分钟内即可对所有用户生效。它会丢弃待处理和已暂存的提交；在按百分比发布的过程中，它会恢复到以 100% 部署的最后一个版本。`newVersion` 必须高于当前已发布的版本。重复回滚会在同样的两个版本之间循环，因此请确保旧版本能够处理新版本写入的数据。

### 评价、评分和指标
```
Use cws-mcp reviews with orderBy="create_time desc", pageSize=20
Use cws-mcp reviews with filter="rating = 1"
Use cws-mcp rating-summary
Use cws-mcp metrics with metrics=["installs","users-7d"], firstDate="2026-10-01", lastDate="2026-10-31", dimension="country"
```

`metrics` 最多接受一个维度。结果是分页的；请将返回的 `nextPageToken` 作为 `pageToken` 传入，其余参数保持完全相同。

## 故障排除

- **缺少凭据 / 401 / 403：** 检查服务器进程的环境，以及对项目和发布者的访问权限。已配置的服务账号密钥优先；无效的服务账号凭据不会回退到 OAuth。
- **项目缺失 / 404：** 请先在 Developer Dashboard 中创建项目，然后传入 `itemId` 或设置 `CWS_ITEM_ID`。没有列出所有项目的工具。
- **无法读取 ZIP：** `zipPath` 必须指向运行 MCP 服务器的机器上可访问的文件（如果在容器中运行，则包括其容器内部）。请在调用 `upload` 或 `submit` 之前构建好 ZIP。
- **上传仍在处理或完成状态未知：** `upload` 和 `submit` 仅在确认上传成功时才报告成功。否则 `submit` 会在发布之前停止；这两个工具都不会自动轮询。在处理可能仍在继续时，请避免再次上传或重复运行 `submit`。请使用 `status` 检查 `lastAsyncUploadState`，只有在确认目标 ZIP 已成功之后，才单独使用 `publish`。此状态涵盖 24 小时内最近一次的异步上传，因此如果发生过其他上传，或者状态缺失或含糊不清，请先在 Developer Dashboard 中核实草稿。
- **已在审核中 / 版本重复：** 请等待审核完成，或在上传前使用 `cancel`；如果版本重复，请提高扩展程序 `manifest.json` 中的版本号并重新构建其 ZIP。
- **上传状态为 `NOT_FOUND`：** 视为上传失败，不会尝试发布。请重新检查项目 ID 并再次上传。
- **上传成功但发布失败：** 如果是 HTTP 错误，请单独重试 `publish`。如果发布请求超时或连接失败，发布结果未知，请先检查 `status`。重新运行 `submit` 会再次上传 ZIP。`submit` 在出现通信错误时会保留已完成的步骤，并返回即时的状态快照；它不会等待审核完成。如果最后的状态步骤失败，请再次检查 `status`；如果摘要中没有提取到问题，请查看原始响应。
- **旧版元数据错误：** 请按照 [商店信息元数据](#商店信息元数据) 中的说明使用 Developer Dashboard。

## 开发

有关本地构建命令和验证，请参阅 [AGENTS.md](AGENTS.md)。有关组件边界、API 映射和提交失败行为，请参阅 [DESIGN.md](DESIGN.md)。

## 许可证

MIT
