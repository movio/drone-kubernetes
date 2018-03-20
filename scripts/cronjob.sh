#!/bin/bash
set -euo pipefail

CRON=${PLUGIN_CRON}

getSpec(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1

  echo "[INFO] Getting current state for ${CLUSTER} ${NAMESPACE} cronjob: ${CRON}"
  kubectl get cronjob ${CRON} -o yaml > ${CRON}.yaml
}


patchSpec(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1

  echo "[INFO] Patching ${CLUSTER} ${NAMESPACE} cronjob: ${CRON}"
  patchjson=$(cat <<EOF
  [
    {
      "op":"replace",
      "path": "/spec/jobTemplate/spec/template/spec/containers/0/image",
      "value":"${PLUGIN_REPO}:${PLUGIN_TAG}"
    }
  ]
  EOF
  )

  kubectl patch -f ${CRON}.yaml --type=json -p=${patchjson}
}

patchCronJob(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1

  getSpec ${CLUSTER} ${NAMESPACE}
  patchSpec ${CLUSTER} ${NAMESPACE}
}
