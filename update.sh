#!/bin/bash
set -euo pipefail

# check optional params
if [ ! -z ${PLUGIN_USER} ]; then
  USER=${PLUGIN_USER:-default}
fi

if [ ! -z ${PLUGIN_NAMESPACE} ]; then
  NAMESPACE=${PLUGIN_NAMESPACE:-default}
fi

# check required params
if [ ! -z ${PLUGIN_CLUSTER} ]; then
  # convert cluster name to ucase and assign
  CLUSTER=${PLUGIN_CLUSTER^^}

  # create dynamic cert var names
  SERVER_URL_VAR=SERVER_URL_${CLUSTER}
  SERVER_CERT_VAR=SERVER_CERT_${CLUSTER}
  CLIENT_CERT_VAR=CLIENT_CERT_${CLUSTER}
  CLIENT_KEY_VAR=CLIENT_KEY_${CLUSTER}

  # expand the var contents
  SERVER_URL=${!SERVER_URL_VAR}
  SERVER_CERT=${!SERVER_CERT_VAR}
  CLIENT_CERT=${!CLIENT_CERT_VAR}
  CLIENT_KEY=${!CLIENT_KEY_VAR}

  if [[ -z "${SERVER_URL}" ]]; then
    echo "[ERROR] drone secret: ${SERVER_URL_VAR} not added!"
    exit 1
  fi

  if [[ ! -z "${SERVER_CERT}" ]]; then
    echo "[INFO] Using secure connection with tls-certificate."
    echo ${SERVER_CERT} | base64 -d > ca.crt
    kubectl config set-cluster default --server=${SERVER_URL} --certificate-authority=ca.crt

    if [[ ! -z "${CLIENT_CERT}" ]] && [[ ! -z "${CLIENT_KEY}" ]]; then
      echo "[INFO] Setting client credentials with signed-certificate and key."
      echo ${CLIENT_CERT} | base64 -d > client.crt
      echo ${CLIENT_KEY} | base64 -d > client.key
      kubectl config set-credentials ${USER} --client-certificate=client.crt --client-key=client.key
    else
      echo "[ERROR] Required plugin parameters:"
      echo " - client_cert"
      echo " - client_key"
      echo "are not provided"
      exit 1
    fi
  else
    echo "[WARNING] Required plugin parameter: ${SERVER_CERT_VAR} not added!"
    echo "[WARNING] Using insecure connection to cluster"
    kubectl config set-cluster default --server=${SERVER_URL} --insecure-skip-tls-verify=true
  fi
else
  echo "[ERROR] Required pipeline parameter: cluster not provided"
  exit 1
fi

kubectl config set-context default --cluster=default --user=${USER}
kubectl config use-context default

# kubectl version
IFS=',' read -r -a DEPLOYMENTS <<< "${PLUGIN_DEPLOYMENT}"
IFS=',' read -r -a CONTAINERS <<< "${PLUGIN_CONTAINER}"
for DEPLOY in ${DEPLOYMENTS[@]}; do
  echo Deploying to ${CLUSTER}
  for CONTAINER in ${CONTAINERS[@]}; do
    kubectl -n ${NAMESPACE} set image deployment/${DEPLOY} \
      ${CONTAINER}="${PLUGIN_REPO}:${PLUGIN_TAG}" --record
  done
done
