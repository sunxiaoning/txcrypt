#!/bin/bash

CONTEXT_DIR=$(dirname "$(realpath "${BASH_SOURCE}")")
SCRIPT_NAME=$(basename "$0")

. ${CONTEXT_DIR}/bashutils/basicenv.sh

. ${CONTEXT_DIR}/app/env.sh
. ${CONTEXT_DIR}/app/keygen.sh
. ${CONTEXT_DIR}/app/crypt.sh

trap __terminate INT TERM
trap __cleanup EXIT

TEMP_FILES=()

main() {
  ACTION="${1-}"
  case "${ACTION}" in
  gen-keypair)
    gen-keypair
    ;;
  remove-keypair)
    remove-keypair
    ;;
  export-keypair)
    export-keypair
    ;;
  export-keypub)
    export-keypub
    ;;
  export-keypriv)
    export-keypriv
    ;;
  import-keypair)
    import-keypair
    ;;
  import-keypub)
    import-keypub
    ;;
  import-keypriv)
    import-keypriv
    ;;
  remove-keypub)
    remove-keypub
    ;;
  remove-keypriv)
    remove-keypriv
    ;;
  encrypt-txt-file)
    encrypt-txt-file
    ;;
  decrypt-txt-file)
    decrypt-txt-file
    ;;
  encrypt-txt)
    encrypt-txt
    ;;
  decrypt-txt)
    decrypt-txt
    ;;
  *)
    echo "The action: ${1-} is not supported!"
    exit 1
    ;;
  esac
}

terminate() {
  echo "[${SCRIPT_NAME}] Terminating..."
}

cleanup() {
  echo "[${SCRIPT_NAME}] Cleanup..."

  if [[ "${#TEMP_FILES[@]}" -gt 0 ]]; then
    echo "Cleaning temp_files...."

    for temp_file in "${TEMP_FILES[@]}"; do
      rm -f "${temp_file}" || true
    done
  fi

  echo "Start cleanup action: ${ACTION} ..."

  case "${ACTION}" in
  autosetup)
    clean-autosetup
    ;;
  *)
    echo "The action: ${1-} cleanup is empty, skip the operation."
    ;;
  esac
}

main "$@"
