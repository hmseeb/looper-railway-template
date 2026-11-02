# Looper (hirelooper/looper, MIT) for Railway. Upstream ships no image, so this builds the
# pinned commit and applies one patch (see below). Context is this repo; source is cloned.
FROM node:22-slim
ARG UPSTREAM_SHA=68eeaeee0713fc4cadb7d796829c3080e765a64e
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN git init -q . && git remote add origin https://github.com/hirelooper/looper.git \
 && git fetch -q --depth 1 origin "$UPSTREAM_SHA" && git checkout -q FETCH_HEAD && rm -rf .git
# Patch: without Loops email codes, upstream's login page shows only Grok plus an official
# "Sign in with ChatGPT" button that redirects to 127.0.0.1 and is disabled on servers.
# Show the Codex device-code sign-in (upstream's own, meant for hosted servers) there instead.
RUN sed -i 's|<ChatGPTButton isLocal={isLocal} />|{isLocal ? <ChatGPTButton isLocal /> : <CodexSignIn label="Continue with ChatGPT" next={target} />}|' src/app/login/page.tsx \
 && grep -q 'isLocal ? <ChatGPTButton isLocal />' src/app/login/page.tsx
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm ci && npm run build
ENV NODE_ENV=production PORT=3000
EXPOSE 3000
# "::" so Railway's IPv6 private network and IPv4 healthchecker both reach it (Node is dual-stack).
CMD ["/app/node_modules/.bin/next", "start", "-H", "::"]
