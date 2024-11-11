KEY_NAME=${KEY_NAME:-""}
KEY_EMAIL=${KEY_EMAIL:-""}
KEY_COMMENT=${KEY_COMMENT:-""}

KEY_IDENTIFIER="${KEY_NAME} (${KEY_COMMENT}) <${KEY_EMAIL}>"

CURRENT_USER="$(__get-current-user)"

DEFAULT_USER=${DEFAULT_USER:-"root"}

is-default-user() {
  [[ "${CURRENT_USER}" == "${DEFAULT_USER}" ]]
}

check-default-user-mode() {
  if __is-sudo; then
    echo "Execution in \"sudo\" mode, abort the operation."
    exit 1
  fi

  if ! is-default-user; then
    echo "Current user: ${CURRENT_USER} is not the default user: ${DEFAULT_USER}, abort the operation."
    exit 1
  fi
}
