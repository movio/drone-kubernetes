#!/bin/bash
set -euo pipefail

JOB=${PLUGIN_JOB}
SPEC=${PLUGIN_SPEC}

runJob(){
  echo "[INFO] Running the ${JOB} job in the ${NAMESPACE} namespace."
  kubectl create -f "${SPEC}" --record
}

waitOnJob(){
  echo "[INFO] Waiting for the job to finish..."
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
  echo "Deleting the job..."
  kubectl delete -f "${SPEC}"
}

startJob(){
  runJob
  waitOnJob
  deleteJob
}
