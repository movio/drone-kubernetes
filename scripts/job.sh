#!/bin/bash
set -euo pipefail

JOB=${PLUGIN_JOB}
SPEC=${PLUGIN_SPEC}

runJob(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1

  echo "[INFO] Running ${JOB} job in the ${CLUSTER}:${NAMESPACE} namespace."
  kubectl create -f "${SPEC}" --record
}

waitOnJob(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1

  echo "[INFO] Waiting for job ${JOB} to finish..."
  while [ true ]; do
    result=`kubectl get job/${JOB} -o jsonpath='{.status.succeeded}'`
    if [[ $result == "1" ]]; then
      break
    else
      sleep 1
    fi
  done
}

deleteJob(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1
  
  echo "[INFO] Deleting job: ${JOB} for ${CLUSTER}:${NAMESPACE}."
  kubectl delete -f "${SPEC}"
}

startJob(){
  local CLUSTER=$1; shift
  local NAMESPACE=$1

  runJob ${CLUSTER} ${NAMESPACE}
  waitOnJob ${CLUSTER} ${NAMESPACE}
  deleteJob ${CLUSTER} ${NAMESPACE}
}
