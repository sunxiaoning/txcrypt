TXT_FILE=${TXT_FILE:-""}

ENCRYPTED_TXT_FILE_FORMAT_BINARY="binary"
ENCRYPTED_TXT_FILE_FORMAT_ASCII="ascii"
ENCRYPTED_TXT_FILE_FORMAT=${ENCRYPTED_TXT_FILE_FORMAT:-"${ENCRYPTED_TXT_FILE_FORMAT_BINARY}"}

default-encrypt-file() {
  if [[ -n "${TXT_FILE}" ]]; then
    case "${ENCRYPTED_TXT_FILE_FORMAT}" in
    "${ENCRYPTED_TXT_FILE_FORMAT_BINARY}")
      echo "${TXT_FILE}.gpg"
      ;;
    "${ENCRYPTED_TXT_FILE_FORMAT_ASCII}")
      echo "${TXT_FILE}.asc"
      ;;
    *)
      echo "The ENCRYPTED_TXT_FILE_FORMAT: ${ENCRYPTED_TXT_FILE_FORMAT} is not supported!"
      exit 1
      ;;
    esac
  else
    echo ""
  fi
}

ENCRYPTED_TXT_FILE=${ENCRYPTED_TXT_FILE:-"$(default-encrypt-file)"}

STDOUT_FILE="/dev/stdout"

DECRPTED_TXT_FILE=${DECRPTED_TXT_FILE:-"${STDOUT_FILE}"}

TXT=${TXT:-""}
ENCRYPTED_TXT=${ENCRYPTED_TXT:-""}

# Non-idempotent operation, each execution will overwrite and generate the latest encrypted text file.

encrypt-txt-file() {
  if [[ -z "${TXT_FILE}" ]]; then
    echo "TXT_FILE param can't be empty!" >&2
    exit 1
  fi

  if [[ ! -f "${TXT_FILE}" ]]; then
    echo "txt file: ${TXT_FILE} is not exists!" >&2
    exit 1
  fi

  check-keypair-param

  check-default-user-mode

  case "${ENCRYPTED_TXT_FILE_FORMAT}" in
  "${ENCRYPTED_TXT_FILE_FORMAT_BINARY}")
    gpg --no-tty --batch --yes --encrypt -q --recipient "${KEY_IDENTIFIER}" -o "${ENCRYPTED_TXT_FILE}" "${TXT_FILE}"
    ;;
  "${ENCRYPTED_TXT_FILE_FORMAT_ASCII}")
    gpg --no-tty --batch --yes --encrypt --armor -q --recipient "${KEY_IDENTIFIER}" -o "${ENCRYPTED_TXT_FILE}" "${TXT_FILE}"
    ;;
  *)
    echo "The ENCRYPTED_TXT_FILE_FORMAT: ${ENCRYPTED_TXT_FILE_FORMAT} is not supported!"
    exit 1
    ;;
  esac

  echo "Encrypted txt file to \"${ENCRYPTED_TXT_FILE}\""
}

# Non-idempotent operation, a new decryption action is performed each time.

decrypt-txt-file() {
  if [[ -z "${ENCRYPTED_TXT_FILE}" ]]; then
    echo "ENCRYPTED_TXT_FILE param can't be empty!" >&2
    exit 1
  fi

  if [[ ! -f "${ENCRYPTED_TXT_FILE}" ]]; then
    echo "txt file: ${ENCRYPTED_TXT_FILE} is not exists!" >&2
    exit 1
  fi

  check-default-user-mode

  local decrypt_content=$(gpg --no-tty --batch --yes --decrypt -q -o "${DECRPTED_TXT_FILE}" "${ENCRYPTED_TXT_FILE}")

  if [[ "${DECRPTED_TXT_FILE}" != "${STDOUT_FILE}" ]]; then
    echo "Decrypted txt file to ${DECRPTED_TXT_FILE}"
  else
    echo "The original txt content is: ${decrypt_content}"
  fi
}

encrypt-txt() {
  if [[ -z "${TXT}" ]]; then
    echo "TXT param can't be empty!" >&2
    exit 1
  fi

  check-keypair-param

  check-default-user-mode

  if [[ -z "${ENCRYPTED_TXT_FILE}" ]]; then
    ENCRYPTED_TXT_FILE="${STDOUT_FILE}"
  fi

  encrypt_content=$(echo "${TXT}" | gpg --no-tty --batch --yes --encrypt --armor -q --recipient "${KEY_IDENTIFIER}" -o "${ENCRYPTED_TXT_FILE}")

  if [[ "${ENCRYPTED_TXT_FILE}" != "${STDOUT_FILE}" ]]; then
    echo "Encrypted txt file to ${ENCRYPTED_TXT_FILE}"
  else
    encrypt_content=$(echo "${encrypt_content}" | base64)
    echo "The encrypted txt content is: ${encrypt_content}"
  fi
}

decrypt-txt() {
  if [[ -z "${ENCRYPTED_TXT}" ]]; then
    echo "ENCRYPTED_TXT param can't be empty!" >&2
    exit 1
  fi

  check-default-user-mode

  local decrypt_content=$(echo "${ENCRYPTED_TXT}" | base64 -d | gpg --no-tty --batch --yes --decrypt -q -o "${DECRPTED_TXT_FILE}")

  if [[ "${DECRPTED_TXT_FILE}" != "${STDOUT_FILE}" ]]; then
    echo "Decrypted txt file to ${DECRPTED_TXT_FILE}"
  else
    echo "The original txt content is: ${decrypt_content}"
  fi
}
