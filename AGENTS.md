# Repository guidance

This repository provides `@kagayoi/cws-mcp`, a stdio MCP server for Chrome Web Store extension management. Read [DESIGN.md](DESIGN.md) for architecture and [README.md](README.md) for user setup and usage.

## Commands and verification

Use **Bun 1.4.4**; `pnpm-lock.yaml` and `pnpm-workspace.yaml` remain authoritative for dependency updates. Bun converts the lock in memory with `--frozen-lockfile --no-save`. Do not introduce another lockfile. The published npm package also supports Node >=20.

```bash
bun install --frozen-lockfile --no-save
bun --bun run build      # tsc -> dist/
bun --no-env-file --no-install src/index.ts  # development
bun --no-env-file --no-install dist/index.js # production (build first)
bun --bun x tsc --noEmit # required after changing src/index.ts
```

There is no dedicated TypeScript application test suite or test runner. Type checking does not execute module-scope schema construction. After runtime/schema changes, also build and smoke-test initialization and tool discovery over stdio (Bash example):

```bash
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | bun --no-env-file --no-install dist/index.js
```

Expect a `serverInfo` result and eight tool definitions. Discovery requires no credentials: authentication is lazy. Actual API calls require the credentials described in README; upload/publish checks change store state, so use only an explicitly authorized item.

## Implementation constraints

- Route authenticated CWS requests through `apiCall` to preserve token caching, timeouts, and cache invalidation on 401/403. Token exchange itself uses the dedicated auth functions. Invalidation affects the next request; it does not retry the failed call.
- Resolve item and publisher IDs with `resolveItemId` / `resolvePublisherId` before building URLs. `itemUrl` expects already encoded path segments; keep upload and v1 URLs equally safe.
- Add tools to `schemas`, `descriptions`, and the main server's `registerTool` calls together. The sandbox discovers tools from `schemas`; verify both surfaces remain aligned.
- Keep `upload` and `submit` on the shared `uploadZip` / `formatUploadResponse` path. HTTP success alone must not permit publishing: require confirmed upload completion as described in [failure behavior](DESIGN.md#request-flow-and-failure-behavior).
- Keep `publish` and `submit` request construction shared through `buildPublishBody`. Preserve completed steps and successful publish responses on `submit` failures. Distinguish a publish HTTP failure from an unknown outcome after a communication error; recovery for the latter starts with `status`. See [failure behavior](DESIGN.md#request-flow-and-failure-behavior).
- Preserve the shared v1 sunset guard for legacy tools and resource metadata. After the cutoff, resource reads must still fetch v2 status without requesting v1 metadata. Descriptions and prompts must not recommend the blocked tools.
- Error hints depend on response wording; preserve HTTP status and raw response context. Missing automatically extracted issues are not evidence of approval.
- Preserve `"types": ["node"]` in `tsconfig.json` for TypeScript 7 and the two-argument zod 4 form `z.record(z.string(), z.unknown())`.
- Keep stdout reserved for MCP protocol traffic; startup failures go to stderr.

## Documentation and distribution maintenance

- Keep user instructions in README, structure and design decisions in DESIGN, and agent commands/constraints here; link rather than duplicate explanations.
- When tool or auth contracts change, check README.md, README.ko.md, llms.txt, smithery.yaml, and server.json together. Keep the npm identifier `@kagayoi/cws-mcp` consistent across distribution metadata.
- Change versions only on explicit release requests. Keep `package.json` and both version fields in `server.json` synchronized. The release workflow checks a `release/x.y.z` branch suffix against `package.json` before publishing.
- `.github/workflows/npm-publish.yml` publishes through npm Trusted Publishing (GitHub OIDC), triggered by `release/**` pushes or `workflow_dispatch`. No npm token is required by this workflow. Preserve its pack-and-verify step and publish the verified `PACKED_TARBALL` without repacking. If distribution contents or entry points change, update the workflow's archive allowlist and manifest assertions together.
- Dependabot covers npm, GitHub Actions, and Docker from the repository root; include all three when maintaining dependency automation.
- Keep dependency validation's type check, build, and credential-free eight-tool discovery check aligned with the verification above.
- After publisher changes, run `pwsh -NoProfile -File scripts/Test-NpmPublisher.ps1 -WorkDirectory <dedicated-absolute-work-path>`. This compiles the C# publisher in memory using PowerShell 7.4+, with no .NET SDK or npm publication runtime. Tests use fixture archives, mocked HTTP/cosign and a localhost redirect check without live credentials. Use an empty work directory and clean its fixture files afterwards. Only an npm version lookup returning 404 permits a new publication attempt.
- For actual Bun archive validation, run `pwsh -NoProfile -File scripts/Test-VerifiedNpmArchive.ps1 -PackageFile <archive> -WorkDirectory <empty-absolute-work-path>` (D: on Windows). This verifies source contents and exercises only the internal unsigned preparation path with deny-only HTTP/signing implementations. Dependency validation reuses its build and toolchain to pack once; release validation reuses `PACKED_TARBALL` without repacking. Both run within existing jobs, without publishing from this test.
