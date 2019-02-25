#!/bin/bash
set -euo pipefail

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )

source "${BASEDIR}/params.sh"
source "${BASEDIR}/cluster-auth.sh"

# Set clusters as csv for eg. : kluster-api,cde-green
IFS=',' read -ra CLUSTERS <<< "$PLUGIN_CLUSTER" 

# Set global params
for i in "${CLUSTERS[@]}"; do
    setGlobals $i
    # Source the right script for kind
    source "${BASEDIR}/${KUBE_KIND,,}.sh"
    
    clusterAuth "${SERVER_URL}" "${CLUSTER}" "${USER}"
    setContext "${CLUSTER}" "${USER}"
    
    if [[ ${KUBE_KIND} == "DEPLOYMENT" ]]; then 
        startDeployments "${CLUSTER}" "${NAMESPACE}"
    elif [[ ${KUBE_KIND} == "DAEMONSET" ]]; then
        startDaemonsets "${CLUSTER}" "${NAMESPACE}"
    fi
done

exit 0