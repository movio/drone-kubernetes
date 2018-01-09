#!/bin/bash
set -euo pipefail

if [ ! -z ${PLUGIN_KUBERNETES_USER} ]; then
  KUBERNETES_USER=${PLUGIN_KUBERNETES_USER:-default}
fi

if [ ! -z ${PLUGIN_KUBERNETES_ENV} ]; then
  KUBERNETES_ENV=${PLUGIN_KUBERNETES_ENV}

  KUBERNETES_SERVER_VAR=KUBERNETES_SERVER_${KUBERNETES_ENV}
  KUBERNETES_CERT_VAR=KUBERNETES_SERVER_CERT_${KUBERNETES_ENV}

  KUBERNETES_SERVER=${!KUBERNETES_SERVER_VAR}
  KUBERNETES_CERT=${!KUBERNETES_CERT_VAR}

  if [[ -z "${KUBERNETES_SERVER}" ]]; then
    echo "ERROR: drone secret ${KUBERNETES_SERVER_VAR} not added!"
    exit 1
  fi

  if [[ -z "${KUBERNETES_CERT}" ]]; then
    echo "ERROR: drone secret ${KUBERNETES_CERT_VAR} not added!"
    echo "Inscure connection to the cluster will be used."
  fi
else
  echo "ERROR: kubernetes_env not provided"
  exit 1
fi

if [ -z ${PLUGIN_NAMESPACE} ]; then
  PLUGIN_NAMESPACE="default"
fi

if [[ ! -z "${KUBERNETES_CLIENT_CERT}" ]] && [[ ! -z "${KUBERNETES_CLIENT_KEY}" ]]; then
  echo "INFO: Setting client credentials with signed-certificate and key."
  echo ${KUBERNETES_CLIENT_CERT} | base64 -d > client.crt
  echo ${KUBERNETES_CLIENT_KEY} | base64 -d > client.key
  kubectl config set-credentials ${KUBERNETES_USER} --client-certificate=client.crt --client-key=client.key
else
  echo "ERROR: Provide the following authentication params:"
  echo " - kubernetes_client_cert"
  echo " - kubernetes_client_key"
  echo "as drone secrets"
  exit 1
fi

if [ ! -z "${KUBERNETES_CERT}" ]; then
  echo "INFO: Using secure connection with tls-certificate."
  echo ${KUBERNETES_CERT} | base64 -d > ca.crt
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --certificate-authority=ca.crt
else
  echo "WARNING: Using insecure connection to cluster"
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --insecure-skip-tls-verify=true
fi

kubectl config set-context default --cluster=default --user=${KUBERNETES_USER}
kubectl config use-context default

# kubectl version
IFS=',' read -r -a DEPLOYMENTS <<< "${PLUGIN_DEPLOYMENT}"
IFS=',' read -r -a CONTAINERS <<< "${PLUGIN_CONTAINER}"
for DEPLOY in ${DEPLOYMENTS[@]}; do
  echo Deploying to ${KUBERNETES_ENV}
  for CONTAINER in ${CONTAINERS[@]}; do
    kubectl -n ${PLUGIN_NAMESPACE} set image deployment/${DEPLOY} \
      ${CONTAINER}=${PLUGIN_REPO}:${PLUGIN_TAG} --record
  done
done
