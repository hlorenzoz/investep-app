#!/usr/bin/env bash
# Deploy de la web a Cloudflare Pages — SOLO en branches `staging` y `main`, en el pre-push.
# En cualquier otra branch no hace nada.
#
# Como corre en el pre-push, el push SOLO se completa si el deploy funcionó.
# Requiere CLOUDFLARE_API_TOKEN en el entorno (o `npx wrangler login`) y un proyecto
# Pages Direct Upload por entorno (investep-app-staging / investep-app-main).
set -euo pipefail

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
case "$branch" in
  staging | main) ;;
  *)
    echo "deploy: omitido (branch '${branch:-?}' ∉ {staging, main})"
    exit 0
    ;;
esac

echo "deploy: desplegando web a Cloudflare Pages (${branch})…"
exec just deploy "$branch"
