#!/bin/bash
set -euo pipefail

# globals
DEPLOYMENTS=""

pollDeploymentRollout(){
  local NAMESPACE=$1; shift
  local TIMEOUT=600
  local SUCCESS_COUNT=${#DEPLOYMENTS[@]}

  # wait on deployments rollout status
  echo ""
  echo "[INFO] Watching rollout status..."
  while true; do
    echo "--------------"
    echo ""
    for DEPLOY in "${DEPLOYMENTS[@]}"; do
      result=$(kubectl -n "${NAMESPACE}" rollout status --watch=false --revision=0 deployment/"${DEPLOY}")
      echo "${DEPLOY}" ":"
      echo "${result}"
      echo ""
      if [[ "${result}" == "deployment \"${DEPLOY}\" successfully rolled out" ]]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT-1))
      fi
    done
    if [ "${SUCCESS_COUNT}" -eq 0 ]; then
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

startDeployments(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1
  IFS=',' read -r -a DEPLOYMENTS <<< "${PLUGIN_DEPLOYMENT}"
  for DEPLOY in "${DEPLOYMENTS[@]}"; do
    echo ""
    echo "[INFO] Deploying ${DEPLOY} to ${CLUSTER} ${NAMESPACE}"
    kubectl -n "${NAMESPACE}" set image deployment/"${DEPLOY}" \
      *="${PLUGIN_REPO}:${PLUGIN_TAG}" --record
  done
  pollDeploymentRollout "${NAMESPACE}"
  exit 0
}
