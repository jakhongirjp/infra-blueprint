#!/usr/bin/env bash
# Renders every Argo CD Application that uses the in-repo service chart with
# its inline values, then runs the policy check on the result. This catches a
# bad values change before Argo CD tries to sync it.
set -euo pipefail
cd "$(dirname "$0")/.."
status=0
for app in k8s/argocd/apps/*/*.yaml; do
  values=$(mktemp)
  python3 - "$app" "$values" <<'PY'
import sys, yaml
app = yaml.safe_load(open(sys.argv[1]))
yaml.safe_dump(app["spec"]["source"]["helm"]["valuesObject"], open(sys.argv[2], "w"))
PY
  release=$(python3 -c "import sys,yaml;print(yaml.safe_load(open(sys.argv[1]))['spec']['source']['helm']['releaseName'])" "$app")
  echo "== $app"
  if ! helm template "$release" k8s/charts/service -f "$values" | python3 scripts/check_chart_policy.py; then
    status=1
  fi
  rm -f "$values"
done
exit $status
