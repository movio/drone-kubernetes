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

    clusterAuth "${SERVER_URL}" "${CLUSTER}" "${USER}" "${ROLE}"
    setContext "${CLUSTER}" "${USER}"

    kubectl get pods -n kube-system
    
    # if [[ ${KUBE_KIND} == "DEPLOYMENT" ]]; then 
    #     startDeployments "${CLUSTER}" "${NAMESPACE}"
    # elif [[ ${KUBE_KIND} == "DAEMONSET" ]]; then
    #     startDaemonsets "${CLUSTER}" "${NAMESPACE}"
    # else
    #     kubectl get pods -n kube-system
    # fi
done

exit 0