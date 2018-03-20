#!/bin/bash
set -euo pipefail

# globals
DEPLOYMENTS=""

pollDeploymentRollout(){
  local DEPLOY=$1; shift
  local TIMEOUT=600

  # wait on deployment rollout status
  echo "[INFO] Watching ${DEPLOY} rollout status..."
  while true; do
    result=`kubectl rollout status --watch=false --revision=0 deployment/${DEPLOY}`
    echo ${result}
    if [[ "${result}" == "deployment \"${DEPLOY}\" successfully rolled out" ]]; then
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

startDeployments(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1

  IFS=',' read -r -a DEPLOYMENTS <<< "${PLUGIN_DEPLOYMENT}"

  for DEPLOY in ${DEPLOYMENTS[@]}; do
    echo "[INFO] Deploying ${DEPLOY} to ${CLUSTER} ${NAMESPACE}"
    kubectl set image deployment/${DEPLOY} \
      *="${PLUGIN_REPO}:${PLUGIN_TAG}" --record
    pollDeploymentRollout ${NAMESPACE} ${DEPLOY}

    if [ "$?" -eq 0 ]; then
      continue
    else
      exit 0
    fi
  done
}
