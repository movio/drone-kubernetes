#!/bin/bash
set -euo pipefail

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )

source ${BASEDIR}/params.sh
source ${BASEDIR}/cluster-auth.sh

# Set global params
setGlobals

# Source the right script for kind
source ${BASEDIR}/${KUBE_KIND,,}.sh


clusterAuth ${SERVER_URL} ${CLUSTER} ${USER}
setContext ${CLUSTER} ${USER}

if [[ ${KUBE_KIND} == "DEPLOYMENT" ]]; then
    startDeployments ${CLUSTER} ${NAMESPACE}
elif [[ ${KUBE_KIND} == "DAEMONSET" ]]; then
    startDaemonsets ${CLUSTER} ${NAMESPACE}
fi