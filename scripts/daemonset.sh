#!/bin/bash
set -euo pipefail

# globals
DAEMONSETS=""

pollDaemonsetRollout(){
  local NAMESPACE=$1; shift
  local DAEMONSET=$1
  local TIMEOUT=600

  # wait on deployment rollout status
  echo "[INFO] Watching ${DAEMONSET} rollout status..."
  while true; do
    result=`kubectl -n ${NAMESPACE} rollout status --watch=false --revision=0 daemonset/${DAEMONSET}`
    echo ${result}
    if [[ "${result}" == "daemon set \"${DAEMONSET}\" successfully rolled out" ]]; then
      return 0
    else
      # TODO: more conditions for error handling based on result text
      sleep 10
      TIMEOUT=$((TIMEOUT-10))
      if [ "${TIMEOUT}" -eq 0 ]; then
        return 1
      fi
    fi
  done
}

startDaemonsets(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1

  IFS=',' read -r -a DAEMONSETS <<< "${PLUGIN_DAEMONSET}"
  for DAEMONSET in ${DAEMONSETS[@]}; do
    echo "[INFO] Deploying ${DAEMONSET} to ${CLUSTER} ${NAMESPACE}"
    kubectl -n ${NAMESPACE} set image daemonset/${DAEMONSET} \
      *="${PLUGIN_REPO}:${PLUGIN_TAG}" --record
    pollDaemonsetRollout ${NAMESPACE} ${DAEMONSET}

    if [ "$?" -eq 0 ]; then
      continue
    else
      exit 0
    fi
  done
}
