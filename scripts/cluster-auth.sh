#!/bin/bash
set -euo pipefail

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )
source "${BASEDIR}/assume-role-aws.sh"

setSecureCluster(){
    local CLUSTER=$1; shift
    local SERVER_URL=$1; shift
    local SERVER_CERT=$1
    
    echo "[INFO] Using secure connection with tls-certificate."
    echo "${SERVER_CERT}" | base64 -d > ${CLUSTER}_ca.crt
    kubectl config set-cluster "${CLUSTER}" --server="${SERVER_URL}" --certificate-authority=${CLUSTER}_ca.crt
}

setInsecureCluster(){
    local CLUSTER=$1; shift
    local SERVER_URL=$1
    
    echo "[WARNING] Using insecure connection to cluster"
    kubectl config set-cluster "${CLUSTER}" --server="${SERVER_URL}" --insecure-skip-tls-verify=true
}

setClientToken(){
    local USER=$1; shift
    local SERVER_TOKEN=$1
    
    echo "[INFO] Setting client credentials with token"
    kubectl config set-credentials "${USER}" --token="${SERVER_TOKEN}"
}

setClientCertAndKey(){
    local USER=$1; shift
    local CLUSTER=$1; shift
    local CLIENT_CERT=$1; shift
    local CLIENT_KEY=$1
    
    echo "[INFO] Setting client credentials with signed-certificate and key."
    echo "${CLIENT_CERT}" | base64 -d > ${CLUSTER}_client.crt
    echo "${CLIENT_KEY}" | base64 -d > ${CLUSTER}_client.key
    kubectl config set-credentials "${USER}" --client-certificate=${CLUSTER}_client.crt --client-key=${CLUSTER}_client.key
}

setAwsAuthenticator(){
    local CLUSTER=$1; shift
    local SERVER_URL=$1;
    
    echo "[INFO] Setting aws iam authenticator in kube config."
    sed -i -e "s~SERVER_ADDRESS~$SERVER_URL~g" /bin/scripts/kubeconfig
    sed -i -e "s~CLUSTER_NAME~$CLUSTER~g" /bin/scripts/kubeconfig
    
    mkdir -p ~/.kube
    cp /bin/scripts/kubeconfig ~/.kube/config

    echo "[INFO] kubectl configured for ${CLUSTER}"
}

setContext(){
    local CLUSTER=$1; shift
    local USER=$1

    if [[ ! "${USER}" == "default" ]]; then
        kubectl config set-context "${CLUSTER}" --cluster="${CLUSTER}" --user="${USER}"
        kubectl config use-context "${CLUSTER}"
    else
        kubectl config use-context "${CLUSTER}"
    fi
}

clientAuthToken(){
    local CLUSTER=$1; shift
    local USER=$1
    
    echo "[INFO] Using Server token to authorize"
    
    CLIENT_TOKEN_VAR=CLIENT_TOKEN_"${CLUSTER}"
    CLIENT_TOKEN=${!CLIENT_TOKEN_VAR}
    
    if [[ ! -z "${CLIENT_TOKEN}" ]]; then
        setClientToken "${USER}" "${CLIENT_TOKEN}"
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
    CLIENT_CERT_VAR=CLIENT_CERT_"${CLUSTER}"
    CLIENT_KEY_VAR=CLIENT_KEY_"${CLUSTER}"
    # expand
    CLIENT_CERT=${!CLIENT_CERT_VAR}
    CLIENT_KEY=${!CLIENT_KEY_VAR}
    
    if [[ ! -z "${CLIENT_CERT}" ]] && [[ ! -z "${CLIENT_KEY}" ]]; then
        setClientCertAndKey "${USER}" "${CLUSTER}" "${CLIENT_CERT}" "${CLIENT_KEY}"
    else
        echo "[ERROR] Required plugin secrets:"
        echo " - ${CLIENT_CERT_VAR}"
        echo " - ${CLIENT_KEY_VAR}"
        echo "not provided"
        exit 1
    fi
}

clientAuthAws(){
    local CLUSTER=$1; shift
    local SERVER_URL=$1; shift
    local ROLE=$1

    echo "[INFO] Using AWS IAM Authenticator to authorize"
    ls -lsa /usr/local/bin | grep aws
    aws-iam-authenticator version
    echo "[INFO] aws-iam-authenticator good to go! Adding to kube config file..."

    if [[ ! "${ROLE}" == "none" ]]; then
        assume_role_aws "${ROLE}" "${FILE}"
    fi

    setAwsAuthenticator "${CLUSTER}" "${SERVER_URL}"
}

clientAuth(){
    local AUTH_MODE=$1; shift
    local CLUSTER=$1; shift
    local USER=$1; shift
    local SERVER_URL=$1; shift
    local ROLE=$1
    
    if [ ! -z "${AUTH_MODE}" ]; then
        if [[ "${AUTH_MODE}" == "token" ]]; then
            clientAuthToken "${CLUSTER}" "${USER}"
        elif [[ "${AUTH_MODE}" == "client-cert" ]]; then
            clientAuthCert "${CLUSTER}" "${USER}"
        elif [[ "${AUTH_MODE}" == "aws-iam-authenticator" ]]; then
            clientAuthAws "${CLUSTER}" "${SERVER_URL}" "${ROLE}"
        else
            echo "[ERROR] Required plugin param - auth_mode - Should be either:"
            echo "[ token | client-cert | aws-iam-authenticator ]"
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
    local USER=$1; shift
    local ROLE=$1

    AUTH_MODE=${PLUGIN_AUTH_MODE}
    SERVER_CERT_VAR=SERVER_CERT_"${CLUSTER}"

    if [[ "${AUTH_MODE}" == "aws-iam-authenticator" ]]; then
        clientAuth "${AUTH_MODE}" "${CLUSTER}" "${USER}" "${SERVER_URL}" "${ROLE}"
    elif [[ ! -z "$SERVER_CERT_VAR}" ]]; then
        SERVER_CERT=${!SERVER_CERT_VAR}
        if [[ ! -z "${SERVER_CERT}" ]]; then
            setSecureCluster "${CLUSTER}" "${SERVER_URL}" "${SERVER_CERT}"
            clientAuth "${AUTH_MODE}" "${CLUSTER}" "${USER}"
        fi
    else
        echo "[WARNING] Required plugin parameter: ${SERVER_CERT_VAR} not added!"
        setInsecureCluster "${CLUSTER}" "${SERVER_URL}"
    fi
}
