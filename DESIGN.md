# System design

## Purpose and boundaries

`@kagayoi/cws-mcp` exposes Chrome Web Store extension management to MCP clients over stdio. It updates existing items; item creation and listing edits after the v1 cutoff belong in the Developer Dashboard. It provides no item enumeration or browser automation.

User configuration and examples are in [README.md](README.md). Development commands, verification, and change constraints are in [AGENTS.md](AGENTS.md).

## Components

All runtime code is in `src/index.ts`; `tsconfig.json` compiles it to `dist/index.js`. The module reads its version from the package root's `package.json`, snapshots environment configuration, registers MCP handlers, and starts the stdio transport. There is no application database; token state is process-local.

| Component | Responsibility and boundary |
|---|---|
| Configuration and ID resolution | Read credentials/default IDs from environment; explicit tool IDs override defaults. Encode IDs as URL path segments. |
| Authentication | Load a service-account key from JSON or a local file and sign an RS256 JWT, or exchange an OAuth refresh token. A configured service account takes precedence; its failure does not fall back to OAuth. |
| `getAccessToken` | Validate token response shape, cache until 60 seconds before expiry, and share one in-flight acquisition among concurrent callers. |
| `apiCall` | Attach Bearer auth, apply request timeouts, return HTTP status/body, and clear the cached token on 401/403 for the next call. No automatic retry. |
| Response helpers | Preserve API responses, add actionable error hints and a best-effort status summary with separate published/submitted revisions and release-channel values. Issue wording/key matching is heuristic; raw status remains necessary. |
| `schemas` / `descriptions` | Shared zod tool contracts for the main server and Smithery's no-op discovery server. Main handlers are registered separately. |
| MCP handlers | Eight tools, one extension resource template, and two prompts. Adapt protocol input to CWS requests and return text/JSON content. |

## API and protocol surfaces

The v2 base is `https://chromewebstore.googleapis.com`; uploads use `/upload/v2/publishers/{publisherId}/items/{itemId}:upload`. Other v2 actions use `/v2/publishers/{publisherId}/items/{itemId}:{action}`.

| Tool | API action |
|---|---|
| `upload` | POST binary ZIP to `upload` |
| `publish` | POST `publish` |
| `status` | GET `fetchStatus` |
| `cancel` | POST `cancelSubmission` |
| `deploy-percentage` | POST `setPublishedDeployPercentage` |
| `submit` | Compose status preflight, upload, publish, and final status |
| `get`, `update-metadata` | Legacy GET/PUT under `https://www.googleapis.com/chromewebstore/v1.1/items/{itemId}` |

The two legacy tools remain registered, but `v1SunsetGuard` returns an error before authentication/network access when the clock is later than `2026-10-15T00:00:00Z`. There is no v2 metadata replacement in this server.

The resource `cws://extensions/{extensionId}` uses the configured publisher and fetches v2 status and published v1 metadata concurrently. Unlike the legacy tools, it does not use the sunset guard: it still attempts metadata retrieval and represents failure as `metadata.unavailable`. Status HTTP errors are included as parsed response data. Resource enumeration is disabled because there is no list-all-items operation.

`publish_extension` and `check_status` generate guidance messages rather than execute tools. Their legacy metadata instructions remain in the prompt text; the tool guard still controls execution.

## Request flow and failure behavior

1. MCP validates tool arguments against the shared schemas. Handlers resolve IDs and, for uploads, synchronously read the ZIP from the server's filesystem into memory.
2. `apiCall` obtains a cached or newly minted token, then calls CWS. Token exchange times out after 30 seconds; CWS requests default to 60 seconds, with 180 seconds for uploads.
3. Tools return the raw successful body or an error with HTTP context and optional hints. `status` also appends a summary; summaries cannot prove that an extension was approved.

`submit` reads the ZIP before any network request. Unless `preflight=false`, it checks item existence: a failed preflight with HTTP 404 or a matching missing-handler message stops submission; other HTTP failures are recorded and upload proceeds. Upload HTTP errors, nonempty `itemError`, or known non-success states stop publishing. The v2 success state is `SUCCEEDED`; the previously accepted `SUCCESS` value remains supported for compatibility. `IN_PROGRESS`, `PROCESSING`, and missing/unparseable upload state do not block the next step; there is no polling loop.

Publish failures stop the flow and explain that the ZIP is already a draft. Successful publish is followed by one status request, not a wait for review completion. A final status HTTP failure is recorded in the steps while the overall submission result remains successful; thrown exceptions return a tool error with completed steps and any successful publish response. A publish communication error leaves its outcome unknown, so recovery starts with `status` before considering another `publish`. HTTP failures retain their raw response bodies, including preflight and final-status failures. The sequence has no transaction or rollback.

## Adopted decisions and tradeoffs

- A single runtime module keeps this small adapter's registrations and helpers together. Shared schemas prevent discovery drift, but main registrations still require explicit synchronization.
- Centralized HTTP/auth handling gives tools and resources consistent limits and token behavior. Single-flight acquisition avoids duplicate token requests; in-memory state is lost on process exit.
- ZIP bytes are forwarded through a view of the read buffer with `application/zip`, avoiding an additional full-archive copy in the adapter. The entire archive is still read into memory, and the server does not build or inspect the extension ZIP.
- v2 is the main management surface. Legacy tool names are retained with a local cutoff instead of issuing post-cutoff requests; resource metadata remains best-effort.
- `publishType` controls publication after approval; `deployPercentage` separately controls rollout share. Optional fields are forwarded only when supplied, leaving omitted defaults to CWS.
- Smithery reuses contracts with no-op handlers for discovery. Importing the module still invokes `main`; the exported factory does not isolate module startup.
- npm runs the compiled stdio entry point. Docker uses a Node 22 multi-stage build, installs production dependencies in the runtime image, and runs as `node`. Smithery maps its config to the same environment variables; `server.json` describes the npm package for MCP Registry clients.
