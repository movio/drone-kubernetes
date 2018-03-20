#!/bin/bash
set -euo pipefail

setSecureCluster(){
  local CLUSTER=$1; shift
  local SERVER_URL=$1; shift
  local SERVER_CERT=$1

  echo "[INFO] Using secure connection with tls-certificate."
  echo ${SERVER_CERT} | base64 -d > ca.crt
  kubectl config set-cluster ${CLUSTER} --server=${SERVER_URL} --certificate-authority=ca.crt
}

setInsecureCluster(){
  local CLUSTER=$1; shift
  local SERVER_URL=$1

  echo "[WARNING] Using insecure connection to cluster"
  kubectl config set-cluster ${CLUSTER} --server=${SERVER_URL} --insecure-skip-tls-verify=true
}

setClientToken(){
  local USER=$1; shift
  local SERVER_TOKEN=$1

  echo "[INFO] Setting client credentials with token"
  kubectl config set-credentials ${USER} --token=${SERVER_TOKEN}
}

setClientCertAndKey(){
  local USER=$1; shift
  local CLIENT_CERT=$1; shift
  local CLIENT_KEY=$1

  echo "[INFO] Setting client credentials with signed-certificate and key."
  echo ${CLIENT_CERT} | base64 -d > client.crt
  echo ${CLIENT_KEY} | base64 -d > client.key
  kubectl config set-credentials ${USER} --client-certificate=client.crt --client-key=client.key
}

setContext(){
  local CLUSTER=$1; shift
  local USER=$1

  kubectl config set-context ${CLUSTER} --cluster=${CLUSTER} --namespace=${NAMESPACE} --user=${USER}
  kubectl config use-context ${CLUSTER}
}

clientAuthToken(){
  local CLUSTER=$1; shift
  local USER=$1

  echo "[INFO] Using Server token to authorize"

  CLIENT_TOKEN_VAR=CLIENT_TOKEN_${CLUSTER}
  CLIENT_TOKEN=${!CLIENT_TOKEN_VAR}

  if [[ ! -z "${CLIENT_TOKEN}" ]]; then
    setClientToken ${USER} ${CLIENT_TOKEN}
  else
    echo "[ERROR] Required plugin secrets:"
    echo " - ${CLIENT_TOKEN_VAR}"
    echo "not provided."
    exit 1
  fi
}

clientAuthCert(){
  local CLUSTER=$1; shift
  local USER=$1

  echo "[INFO] Using Client cert and Key to authorize"
  CLIENT_CERT_VAR=CLIENT_CERT_${CLUSTER}
  CLIENT_KEY_VAR=CLIENT_KEY_${CLUSTER}
  # expand
  CLIENT_CERT=${!CLIENT_CERT_VAR}
  CLIENT_KEY=${!CLIENT_KEY_VAR}

  if [[ ! -z "${CLIENT_CERT}" ]] && [[ ! -z "${CLIENT_KEY}" ]]; then
    setClientCertAndKey ${USER} ${CLIENT_CERT} ${CLIENT_KEY}
  else
    echo "[ERROR] Required plugin secrets:"
    echo " - ${CLIENT_CERT_VAR}"
    echo " - ${CLIENT_KEY_VAR}"
    echo "not provided"
    exit 1
  fi
}

clientAuth(){
  local AUTH_MODE=$1; shift
  local CLUSTER=$1; shift
  local USER=$1

  if [ ! -z ${AUTH_MODE} ]; then
    if [[ "${AUTH_MODE}" == "token" ]]; then
      clientAuthToken ${CLUSTER} ${USER}
    elif [[ "${AUTH_MODE}" == "client-cert" ]]; then
      clientAuthCert ${CLUSTER} ${USER}
    else
      echo "[ERROR] Required plugin param - auth_mode - Should be either:"
      echo "[ token | client-cert ]"
      exit 1
    fi
  else
    echo "[ERROR] Required plugin param - auth_mode - not provided"
    exit 1
  fi
}

clusterAuth(){
  local SERVER_URL=$1; shift
  local CLUSTER=$1; shift
  local USER=$1

  SERVER_CERT_VAR=SERVER_CERT_${CLUSTER}
  SERVER_CERT=${!SERVER_CERT_VAR}

  if [[ ! -z "${SERVER_CERT}" ]]; then
    setSecureCluster ${CLUSTER} ${SERVER_URL} ${SERVER_CERT}
    AUTH_MODE=${PLUGIN_AUTH_MODE}
    clientAuth ${AUTH_MODE} ${CLUSTER} ${USER}
  else
    echo "[WARNING] Required plugin parameter: ${SERVER_CERT_VAR} not added!"
    setInsecureCluster ${CLUSTER} ${SERVER_URL}
  fi
}
