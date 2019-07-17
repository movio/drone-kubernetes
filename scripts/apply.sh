#!/bin/sh

set -euo pipefail

applyConfiguration() {
  local DIR=$1; shift
  local FILE=$1
  declare -a files

  if [[ -z $DIR ]]; then
    echo "[ERROR] Required variable DIR in order to run 'kubectl apply -f' "
    exit 1
  fi

  if [[ "$(declare -p ${DIR})" =~ "declare -a" ]]; then
    for dir in "${DIR[@]}"; do
      echo "Applying changes from folder: ${dir}"
      for file in "${dir}/*.yml"; do
        files=( "${files[@]}" "${dir}/${file}" )
        echo "File: $file"
      done
      echo "Files: $files"
      for file in "${files}"; do
        # result=$(kubectl apply -f ${file})
        echo "kubectl apply -f ${file}"
        # if [[ "${result}" == "daemon set \"${DAEMONSET}\" successfully rolled out" ]]; then
        #   SUCCESS_COUNT=$((SUCCESS_COUNT+1))
        # fi
      done
    done
  elif [[ $FILE != "none" ]]; then
    echo "kubectl apply -f ${FILE}"
  fi

}