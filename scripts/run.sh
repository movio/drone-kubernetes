#!/bin/bash
set -euo pipefail

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )

source ${BASEDIR}/params.sh
source ${BASEDIR}/cluster-auth.sh
source ${BASEDIR}/deploy.sh

setGlobals
clusterAuth ${SERVER_URL} ${CLUSTER} ${USER}
setContext ${CLUSTER} ${USER}
startDeployments ${CLUSTER} ${NAMESPACE}
