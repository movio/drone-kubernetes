#!/bin/bash
set -euo pipefail

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )

source ${BASEDIR}/params.sh
source ${BASEDIR}/cluster-auth.sh

setGlobals
clusterAuth ${SERVER_URL} ${CLUSTER} ${USER}
setContext ${CLUSTER} ${USER}

if [[ ${KUBE_KIND} == "DEPLOYMENT" ]]; then
  source ${BASEDIR}/deploy.sh
  startDeployments ${CLUSTER} ${NAMESPACE}
elif [[ "${KUBE_KIND}" == "JOB"]]; then
  source ${BASEDIR}/job.sh
  startJob ${CLUSTER} ${NAMESPACE}
fi
