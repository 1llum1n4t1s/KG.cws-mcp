# Repository guidance

This repository provides `@kagayoi/cws-mcp`, a stdio MCP server for Chrome Web Store extension management. Read [DESIGN.md](DESIGN.md) for architecture and [README.md](README.md) for user setup and usage.

## Commands and verification

Use **pnpm**; `pnpm-lock.yaml` and `pnpm-workspace.yaml` are authoritative. Do not introduce `package-lock.json`. The runtime declares Node >=20; CI and Docker use Node 22 and pnpm 11.

```bash
pnpm install             # CI/Docker use --frozen-lockfile
pnpm build               # tsc -> dist/
pnpm dev                 # tsx src/index.ts
pnpm start               # node dist/index.js (build first)
pnpm exec tsc --noEmit   # required after changing src/index.ts
```

There is no test suite or test runner. Type checking does not execute module-scope schema construction. After runtime/schema changes, also build and smoke-test initialization and tool discovery over stdio (Bash example):

```bash
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | node dist/index.js
```

Expect a `serverInfo` result and eight tool definitions. Discovery requires no credentials: authentication is lazy. Actual API calls require the credentials described in README; upload/publish checks change store state, so use only an explicitly authorized item.

## Implementation constraints

- Route authenticated CWS requests through `apiCall` to preserve token caching, timeouts, and cache invalidation on 401/403. Token exchange itself uses the dedicated auth functions. Invalidation affects the next request; it does not retry the failed call.
- Resolve item and publisher IDs with `resolveItemId` / `resolvePublisherId` before building URLs. `itemUrl` expects already encoded path segments; keep upload and v1 URLs equally safe.
- Add tools to `schemas`, `descriptions`, and the main server's `registerTool` calls together. The sandbox discovers tools from `schemas`; verify both surfaces remain aligned.
- Keep `publish` and `submit` request construction shared through `buildPublishBody`. Preserve partial-failure details so users do not unnecessarily upload again after a publish failure.
- Preserve the v1 tool sunset guard. The resource has a separate best-effort metadata path, described in DESIGN; do not assume the guard applies to it.
- Error hints depend on response wording; preserve HTTP status and raw response context. Missing automatically extracted issues are not evidence of approval.
- Preserve `"types": ["node"]` in `tsconfig.json` for TypeScript 7 and the two-argument zod 4 form `z.record(z.string(), z.unknown())`.
- Keep stdout reserved for MCP protocol traffic; startup failures go to stderr.

## Documentation and distribution maintenance

- Keep user instructions in README, structure and design decisions in DESIGN, and agent commands/constraints here; link rather than duplicate explanations.
- When tool or auth contracts change, check README.md, README.ko.md, llms.txt, smithery.yaml, and server.json together. Keep the npm identifier `@kagayoi/cws-mcp` consistent across distribution metadata.
- Change versions only on explicit release requests. Keep `package.json` and both version fields in `server.json` synchronized. The release workflow checks a `release/x.y.z` branch suffix against `package.json` before publishing.
- `.github/workflows/npm-publish.yml` publishes through npm Trusted Publishing (GitHub OIDC), triggered by `release/**` pushes or `workflow_dispatch`. No npm token is required by this workflow.
- Dependabot covers npm, GitHub Actions, and Docker from the repository root; include all three when maintaining dependency automation.
