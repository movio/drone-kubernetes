#!/bin/bash
set -euo pipefail

# globals
USER=""
NAMESPACE=""
CLUSTER=""
SERVER_URL=""
KUBE_KIND=""

# set globals
setUser(){
  USER=${PLUGIN_USER:-default}
}

setNamespace(){
  NAMESPACE=${PLUGIN_NAMESPACE:-default}
}

setCluster(){
  if [ ! -z ${PLUGIN_CLUSTER} ]; then
    # convert cluster name to ucase and assign
    CLUSTER=${PLUGIN_CLUSTER^^}
  else
    echo "[ERROR] Required pipeline parameter: 'cluster' not provided"
    exit 1
  fi
}

setKind(){
  if [ ! -z ${PLUGIN_KIND} ]; then
    KUBE_KIND=${PLUGIN_KIND^^}
    if [[ ! "${KUBE_KIND}" =~ ^(DEPLOYMENT|JOB|CRONJOB)$ ]]; then
      echo "[ERROR] Unsupported kubernetes kind: ${KUBE_KIND}"
      echo "[INFO] Supported kinds: [ deployment, job, cronjob ]"
      exit 1
    fi
  else
    echo "[ERROR] Required pipeline parameter: 'kind' not provided"
    exit 1
  fi
}

setServerUrl(){
  # create dynamic cert var names
  local SERVER_URL_VAR=SERVER_URL_${CLUSTER}
  SERVER_URL=${!SERVER_URL_VAR}
  if [[ -z "${SERVER_URL}" ]]; then
    echo "[ERROR] Required drone secret: '${SERVER_URL_VAR}' not added!"
    exit 1
  fi
}

setGlobals(){
  setUser
  setNamespace
  setCluster
  setKind
  setServerUrl
}
