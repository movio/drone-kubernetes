#!/bin/sh

set -e

assume_role_aws() {

  local ROLE=$1; shift
  local FILE=$1

  if [ -z $ROLE ];
  then
      echo "Error: please provide aws role to assume"
      exit 1
  fi

  if [ -z $FILE ];
  then
      PLUGIN_FILE=".env"
  fi

  echo "Assuming: ${ROLE}"
  CREDS=`aws sts assume-role --role-arn ${ROLE} --role-session-name=${DRONE_REPO_OWNER}-${DRONE_REPO_NAME}`

  export AWS_ACCESS_KEY_ID=`echo $CREDS | jq -r '.Credentials.AccessKeyId'`
  export AWS_SECRET_ACCESS_KEY=`echo $CREDS | jq -r '.Credentials.SecretAccessKey'`
  export AWS_SESSION_TOKEN=`echo $CREDS | jq -r '.Credentials.SessionToken'`

  echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> ${FILE}
  echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> ${FILE}
  echo "export AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}" >> ${FILE}
}
