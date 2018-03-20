#!/bin/bash
set -euo pipefail

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )

KUBE_KIND=${PLUGIN_KIND}

source ${BASEDIR}/params.sh
source ${BASEDIR}/cluster-auth.sh

setGlobals
clusterAuth ${SERVER_URL} ${CLUSTER} ${USER}
setContext ${CLUSTER} ${USER}

if [[ ${KUBE_KIND} == "deployment" ]]; then
  source ${BASEDIR}/deploy.sh
  startDeployments ${CLUSTER} ${NAMESPACE}
elif [[ "${KUBE_KIND}" == "job"]]; then
  source ${BASEDIR}/job.sh
  startJob ${CLUSTER} ${NAMESPACE}
else
  echo "[ERROR] Unsupported kubernetes kind: ${KUBE_KIND}"
  echo "[INFO] Supported kinds: [ deployment, job ]"
  exit 1
fi
