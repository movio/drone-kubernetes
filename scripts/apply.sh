#!/bin/sh

set -euo pipefail

is_array()
{   #detect if arg is an array, returns 0 on sucess, 1 otherwise
    [ -z "$1" ] && return 1
    if [ -n "$BASH" ]; then
        declare -p ${1} 2> /dev/null | grep 'declare \-a' >/dev/null && return 0
    fi
    return 1
}

applyConfiguration() {
  local DIR=$1; shift
  local K8S_FILE=$1

  if [[ $K8S_FILE != "none" ]]; then

    if [[ $K8S_FILE == *","* ]]; then
      IFS=',' read -ra FILES <<< $K8S_FILE

      for f in "${FILES[@]}"; do
        echo "[INFO] Applying changes with file: ${f}"
        echo "kubectl apply -f ${f}"
      done

    else
      echo "[INFO] Applying changes with file: ${FILE}"
      echo "kubectl apply -f ${FILE}"
      kubectl apply -f 
    fi

  elif [[ $DIR != "." ]]; then
    declare -a files
    
    if [[ $DIR == *","* ]]; then
      IFS=',' read -ra DIRS <<< "$DIR"

      for dir in "${DIRS[@]}"; do
        echo "[INFO] Applying changes from folder: ${dir}"
        for file in "${dir}"/*; do
          if [[ ${file: -4} == ".yml" ]]; then 
            files=( "${files[@]}" "${dir}/${file}" )
          fi
        done
        for file in "${files[@]}"; do
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
  fi

}
