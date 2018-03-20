#!/bin/bash
set -euo pipefail

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )

source ${BASEDIR}/params.sh
source ${BASEDIR}/cluster-auth.sh

setGlobals
clusterAuth ${SERVER_URL} ${CLUSTER} ${USER}
setContext ${CLUSTER} ${USER}

source ${BASEDIR}/${KUBE_KIND,,}.sh

if [[ ${KUBE_KIND} == "DEPLOYMENT" ]]; then
  startDeployments ${CLUSTER} ${NAMESPACE}
elif [[ "${KUBE_KIND}" == "JOB" ]]; then
  startJob ${CLUSTER}
fi
