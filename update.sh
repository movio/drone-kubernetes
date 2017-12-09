#!/bin/bash

if [ -z ${PLUGIN_NAMESPACE} ]; then
  PLUGIN_NAMESPACE="default"
fi

if [ ! -z ${PLUGIN_KUBERNETES_TOKEN} ]; then
  KUBERNETES_TOKEN=$PLUGIN_KUBERNETES_TOKEN
fi

if [ ! -z ${PLUGIN_KUBERNETES_CLIENT_CERT} ]; then
  KUBERNETES_CLIENT_CERT=$PLUGIN_KUBERNETES_CLIENT_CERT
fi

if [ ! -z ${PLUGIN_KUBERNETES_CLIENT_KEY} ]; then
  KUBERNETES_CLIENT_KEY=$PLUGIN_KUBERNETES_CLIENT_KEY
fi

if [ ! -z ${PLUGIN_KUBERNETES_SERVER} ]; then
  KUBERNETES_SERVER=$PLUGIN_KUBERNETES_SERVER
fi

if [ ! -z ${PLUGIN_KUBERNETES_CERT} ]; then
  KUBERNETES_CERT=${PLUGIN_KUBERNETES_CERT}
fi

if [ ! -z ${PLUGIN_KUBERNETES_USER} ]; then
  KUBERNETES_USER=${PLUGIN_KUBERNETES_USER:-default}
fi

if [ ! -z ${KUBERNETES_CLIENT_CERT} ] && [ ! -z ${KUBERNETES_CLIENT_KEY} ]; then
  echo "INFO: Setting client credentials with signed-certificate and key."
  echo ${KUBERNETES_CLIENT_CERT} | base64 -d > client.crt
  echo ${KUBERNETES_CLIENT_KEY} | base64 -d > client.key
  kubectl config set-credentials ${KUBERNETES_USER} --client-certificate=client.crt --client-key=client.key
else
  echo "INFO: Setting client credentials with token."
  kubectl config set-credentials ${KUBERNETES_USER} --token=${KUBERNETES_TOKEN}
fi

if [ ! -z ${KUBERNETES_CERT} ]; then
  echo "INFO: Using secure connection with tls-certificate."
  echo ${KUBERNETES_CERT} | base64 -d > ca.crt
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --certificate-authority=ca.crt
else
  echo "WARNING: Using insecure connection to cluster"
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --insecure-skip-tls-verify=true
fi

kubectl config set-context default --cluster=default --user=default
kubectl config use-context default

# kubectl version
IFS=',' read -r -a DEPLOYMENTS <<< "${PLUGIN_DEPLOYMENT}"
IFS=',' read -r -a CONTAINERS <<< "${PLUGIN_CONTAINER}"
for DEPLOY in ${DEPLOYMENTS[@]}; do
  echo Deploying to $KUBERNETES_SERVER
  for CONTAINER in ${CONTAINERS[@]}; do
    kubectl -n ${PLUGIN_NAMESPACE} set image deployment/${DEPLOY} \
      ${CONTAINER}=${PLUGIN_REPO}:${PLUGIN_TAG} --record
  done
done
