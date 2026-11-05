# ── Build stage: install full deps and compile TypeScript ──
FROM oven/bun:1.4.4-alpine AS build
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.json bunfig.toml ./
RUN bun install --network-concurrency=4 --frozen-lockfile --no-save
COPY src/ ./src/
RUN bun --bun run build

# ── Runtime stage: production deps + compiled output only ──
FROM oven/bun:1.4.4-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml bunfig.toml ./
RUN bun install --network-concurrency=4 --frozen-lockfile --no-save --production
COPY --from=build /app/dist ./dist
USER bun
ENTRYPOINT ["bun", "--no-env-file", "--no-install", "dist/index.js"]
