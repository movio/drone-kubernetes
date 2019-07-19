#!/bin/sh

set -euo pipefail

applyConfiguration() {
  local DIR=$1; shift
  local K8S_FILE=$1

## K8S fles takes precedence over DIR
  if [[ $K8S_FILE != "none" ]]; then
    if [[ $K8S_FILE == *","* ]]; then
      IFS=',' read -ra FILES <<< $K8S_FILE

      for f in "${FILES[@]}"; do
        if [[ ${f: -4} != ".yml" ]]; then
          echo "[ERROR] File $f is not an YAML file."
          exit 1
        else
          echo "[INFO] Applying file: ${f}"
          kubectl apply -f ${f}
        fi
      done
    else
      if [[ ${K8S_FILE: -4} != ".yml" ]]; then
        echo "[ERROR] File $K8S_FILE is not an YAML file."
        exit 1
      else
        echo "[INFO] Applying file: ${K8S_FILE}"
        kubectl apply -f ${K8S_FILE}
      fi
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
          echo "[INFO] Applying file: ${file}"
          kubectl apply -f ${file}
        done
      done
    fi
  fi

}
