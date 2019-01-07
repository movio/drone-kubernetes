#!/bin/bash
set -euo pipefail

patchAppConfigMapWithMeta(){
  if [ ! -z "${PLUGIN_CONFIG_MAP_KEY:-}" ]; then
    local configMapKey=${PLUGIN_CONFIG_MAP_KEY,,}
    local meta=("GIT_COMMIT_SHA" "${DRONE_COMMIT_SHA}")
    local metaJson="{$(printf '"%s":"%s",' "${meta[@]}" | sed '$s/,$//')}"
    kubectl patch configmap "${configMapKey}" -p "${metaJson}"
  fi
}
