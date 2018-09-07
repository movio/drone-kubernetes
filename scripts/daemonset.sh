#!/bin/bash
set -euo pipefail

# globals
DAEMONSETS=""

pollDaemonsetRollout(){
  local NAMESPACE=$1; shift
  local TIMEOUT=600
  local SUCCESS_COUNT=${#DAEMONSETS[@]}

  # wait on DAEMONSETS rollout status
  echo ""
  echo "[INFO] Watching rollout status..."
  while true; do
    echo "--------------"
    echo ""
    SUCCESS_COUNT=0
    for DAEMONSET in "${DAEMONSETS[@]}"; do
      result=$(kubectl -n "${NAMESPACE}" rollout status --watch=false --revision=0 ds/"${DAEMONSET}")
      echo "${DAEMONSET} :"
      echo "${result}"
      echo ""
      if [[ "${result}" == "daemonset \"${DAEMONSET}\" successfully rolled out" ]]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT+1))
      fi
    done
    if [ "${#DAEMONSETS[@]}" == "$SUCCESS_COUNT" ]; then
      echo "--------------" 
      echo ""
      echo "All deployed successfully!"
      return 0
    else
      # TODO: more conditions for error handling based on result text
      echo "--------------" 
      echo ""
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
  for DAEMONSET in "${DAEMONSETS[@]}"; do
    echo ""
    echo "[INFO] Deploying ${DAEMONSET} to ${CLUSTER} ${NAMESPACE}"
    kubectl -n "${NAMESPACE}" set image ds/"${DAEMONSET}" \
      *="${PLUGIN_REPO}:${PLUGIN_TAG}" --record
  done
  pollDaemonsetRollout "${NAMESPACE}"
  exit 0
}
