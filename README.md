# @kagayoi/cws-mcp

[![npm version](https://img.shields.io/npm/v/@kagayoi/cws-mcp)](https://www.npmjs.com/package/@kagayoi/cws-mcp)

[한국어](README.ko.md)

MCP server for Chrome Web Store extension management. Upload, publish, and manage Chrome extensions directly from Claude Code or any MCP client.

> Fork of [mikusnuz/cws-mcp](https://github.com/mikusnuz/cws-mcp), updated for the Chrome Web Store **API V2**: service-account auth, a working OAuth flow (Google removed the old `oob` flow), and the latest MCP SDK.

## When to Use

Use this MCP when you need to:

- **"Upload a new version of my Chrome extension"** — build your ZIP and use the `upload` tool to push it as a draft
- **"Publish my extension to the Chrome Web Store"** — use `publish` to submit for review and go live
- **"Check the review status of my extension"** — use `status` to see review state, version, and deploy percentage
- **"Upload and publish in one step"** — use `submit` to run upload → publish → status as a single call
- **"Cancel a pending submission"** — use `cancel` to withdraw a submission under review
- **"Set up staged rollout for my extension"** — use `publish` with `deployPercentage`, then `deploy-percentage` to ramp up

## Tools

| Tool | Description |
|---|---|
| `upload` | Upload a ZIP file to Chrome Web Store (update existing item draft) |
| `publish` | Publish an extension with optional staged rollout, publish type, and skip-review |
| `status` | Fetch the current status including review state, deploy percentage, and version |
| `cancel` | Cancel a pending submission |
| `deploy-percentage` | Set staged rollout percentage (0-100, must exceed current target) |
| `get`, `update-metadata` | Legacy metadata tools; blocked by the server after its v1 cutoff (see below) |
| `submit` | One-shot: run upload → publish → status in a single call (with existence preflight and readable errors) |

> The Chrome Web Store API cannot create items. Create a new item manually in the Chrome Web Store Developer Dashboard, then use `upload` / `publish` (or `submit`) against its item ID.

## Listing metadata

The server blocks `get` and `update-metadata` when its clock is later than **2026-10-15 00:00 UTC**, before making an API request. These legacy tools remain visible in discovery, but cannot be used after that cutoff. Edit listing text and other metadata manually in the Chrome Web Store Developer Dashboard; this server has no v2 metadata replacement or browser automation.

## Setup

Install Node.js **20 or newer** on the machine running the MCP server. The npm configuration below runs the package through `npx`; no global package installation is needed.

Authenticate with **either** a service account (recommended, ideal for CI/CD) **or** an OAuth2 refresh token.

### Option A — Service Account (recommended)

1. In the [Google Cloud Console](https://console.cloud.google.com/), create/select a project and enable the **Chrome Web Store API**.
2. Create a **Service Account**, then add a **JSON key** (Keys → Add key → Create new key → JSON).
3. In the [Developer Dashboard](https://chrome.google.com/webstore/devconsole) → **Account**, add the service account's email to grant it API access to your publisher account.
4. Set `CWS_SERVICE_ACCOUNT_KEY` to the **path of the JSON key file** (or its raw JSON contents).

See [Use a service account with the Chrome Web Store API](https://developer.chrome.com/docs/webstore/service-accounts) for details.

### Option B — OAuth2 Refresh Token

1. In the [Google Cloud Console](https://console.cloud.google.com/), create/select a project and enable the **Chrome Web Store API**.
2. Create **OAuth2 credentials** of type **Desktop app**. Note the **Client ID** and **Client Secret**.
3. Obtain a refresh token using a **loopback redirect**. (The old `urn:ietf:wg:oauth:2.0:oob` flow was removed by Google in 2022 and no longer works — desktop clients now use `http://localhost`.)

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

   The response contains your `refresh_token`. Any `http://localhost[:PORT]` or `http://127.0.0.1[:PORT]` redirect is accepted for Desktop-app clients.

### Configure MCP

Add the following server definition to your MCP client's configuration. The example uses the `mcpServers` format; use your client's documented configuration location or server-add command.

**Via npm with a service account (recommended):**

```json
{
  "mcpServers": {
    "cws-mcp": {
      "command": "npx",
      "args": ["-y", "@kagayoi/cws-mcp"],
      "env": {
        "CWS_SERVICE_ACCOUNT_KEY": "/path/to/service-account.json",
        "CWS_PUBLISHER_ID": "me",
        "CWS_ITEM_ID": "your-extension-id"
      }
    }
  }
}
```

**Via npm with an OAuth refresh token:**

```json
{
  "mcpServers": {
    "cws-mcp": {
      "command": "npx",
      "args": ["-y", "@kagayoi/cws-mcp"],
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

## Environment Variables

Provide **either** a service-account key (Auth A) **or** the OAuth2 refresh-token trio (Auth B).

| Variable | Required | Description |
|---|---|---|
| `CWS_SERVICE_ACCOUNT_KEY` | Auth A | Path to a service-account JSON key file, or the raw JSON string. Takes precedence over OAuth when set. |
| `CWS_CLIENT_ID` | Auth B | Google OAuth2 Client ID |
| `CWS_CLIENT_SECRET` | Auth B | Google OAuth2 Client Secret |
| `CWS_REFRESH_TOKEN` | Auth B | OAuth2 Refresh Token |
| `CWS_PUBLISHER_ID` | No | Publisher ID (default: `me`) |
| `CWS_ITEM_ID` | No | Default extension item ID |

## Usage Examples

### Check extension status
```
Use the cws-mcp status tool
```

### Upload and publish
```
1. Use cws-mcp upload with zipPath="/path/to/extension.zip"
2. Use cws-mcp publish
```

### Publish with an initial rollout percentage
```
Use cws-mcp publish with:
- deployPercentage=10
```

`publishType="STAGED_PUBLISH"` instead stages the approved version for manual publication; it does not itself set the rollout percentage. The default publication type publishes after approval. `skipReview=true` only attempts to skip review when eligible.

### Publish with skip-review
```
Use cws-mcp publish with skipReview=true
```

### Staged rollout
```
1. Use cws-mcp publish with deployPercentage=10
2. After approval and publication, check the current target with cws-mcp status
3. Use cws-mcp deploy-percentage with percentage=50
4. Use cws-mcp deploy-percentage with percentage=100
```

Note: `deploy-percentage` is only available for extensions with 10,000+ seven-day active users. The new percentage must always be higher than the current target.

## Troubleshooting

- **Missing credentials / 401 / 403:** check the environment of the server process and item/publisher access. A configured service-account key takes precedence; invalid service-account credentials do not fall back to OAuth.
- **Missing item / 404:** create the item in the Developer Dashboard first, then pass `itemId` or set `CWS_ITEM_ID`. There is no list-all-items tool.
- **Unreadable ZIP:** `zipPath` must point to a file accessible on the machine running the MCP server, including inside its container if applicable. Build the ZIP before calling `upload` or `submit`.
- **Already in review / duplicate version:** wait for review or use `cancel` before uploading; for a duplicate version, increase the extension's `manifest.json` version and rebuild its ZIP.
- **Upload succeeded but publish failed:** for an HTTP error, retry `publish` alone. If the publish request timed out or the connection failed, check `status` first because the publish result is unknown. Re-running `submit` uploads the ZIP again. `submit` retains completed steps on communication errors and returns an immediate status snapshot; it does not wait for review completion. Check `status` again if the final status step failed, and inspect the raw response when a summary has no extracted issues.
- **Legacy metadata error:** use the Developer Dashboard as described under [Listing metadata](#listing-metadata).

## Development

For local build commands and verification, see [AGENTS.md](AGENTS.md). For component boundaries, API mapping, and submission failure behavior, see [DESIGN.md](DESIGN.md).

## License

MIT
