KEY_TYPE="RSA"
KEY_LENGTH="2048"

OPS_KEYS_MOD_PUB="pub"
OPS_KEYS_MOD_PRIV="priv"
OPS_KEYS_MOD_PAIR="pair"

OPS_KEYS_MOD=""

PUB_KEY_FILE=${PUB_KEY_FILE:-"pub.asc"}
PRIV_KEY_FILE=${PRIV_KEY_FILE:-"priv.asc"}

gen-keypair() {
  check-keypair-param

  check-default-user-mode

  if gpg --list-keys --with-colons -q | grep -q "^uid:.*${KEY_IDENTIFIER}"; then
    echo "GPG key with identifier '$KEY_IDENTIFIER' already exists. Skipping key generation."
    return 0
  fi

  gpg --no-tty --batch --generate-key <<EOF
%no-protection
%pinentry-mode loopback
%use-agent
%transient-key
Key-Type: ${KEY_TYPE}
Key-Length: ${KEY_LENGTH}
Subkey-Type: ${KEY_TYPE}
Subkey-Length: ${KEY_LENGTH}
Name-Real: ${KEY_NAME}
Name-Email: ${KEY_EMAIL}
Name-Comment: ${KEY_COMMENT}
Expire-Date: 0
%commit
EOF

  echo "Generated key pair for ${KEY_IDENTIFIER}."
}

remove-keypair() {
  OPS_KEYS_MOD="${OPS_KEYS_MOD_PAIR}"
  remove-keys

  echo "Removed key pair for ${KEY_IDENTIFIER}."
}

export-keypair() {
  OPS_KEYS_MOD="${OPS_KEYS_MOD_PAIR}"
  export-keys

  echo "Exported key pair for ${KEY_IDENTIFIER}."
}

export-keypub() {
  OPS_KEYS_MOD="${OPS_KEYS_MOD_PUB}"
  export-keys

  echo "Exported pubkey for ${KEY_IDENTIFIER}."
}

export-keypriv() {
  OPS_KEYS_MOD="${OPS_KEYS_MOD_PRIV}"
  export-keys

  echo "Exported privkey for ${KEY_IDENTIFIER}."
}

import-keypair() {
  OPS_KEYS_MOD="${OPS_KEYS_MOD_PAIR}"
  import-keys

  echo "Imported key pair for ${KEY_IDENTIFIER}."
}

import-keypub() {
  OPS_KEYS_MOD="${OPS_KEYS_MOD_PUB}"
  import-keys

  echo "Imported keypub for ${KEY_IDENTIFIER}."
}

import-keypriv() {
  OPS_KEYS_MOD="${OPS_KEYS_MOD_PRIV}"
  import-keys

  echo "Imported keypriv for ${KEY_IDENTIFIER}."
}

import-keys() {
  check-keypair-param

  check-default-user-mode

  case "${OPS_KEYS_MOD}" in
  "${OPS_KEYS_MOD_PUB}")
    import-key "${PUB_KEY_FILE}"
    ;;
  "${OPS_KEYS_MOD_PRIV}")
    import-key "${PRIV_KEY_FILE}"
    ;;
  "${OPS_KEYS_MOD_PAIR}")
    import-key "${PUB_KEY_FILE}"
    import-key "${PRIV_KEY_FILE}"
    ;;
  *)
    echo "The OPS_KEYS_MOD: ${OPS_KEYS_MOD} is not supported!"
    exit 1
    ;;
  esac
}

import-key() {
  local key_file="${1-}"
  gpg --import "${key_file}"

  if ! gpg --list-keys --with-colons -q | grep -q "^uid:.*${KEY_IDENTIFIER}"; then
    echo "GPG key with identifier '$KEY_IDENTIFIER' is not exists." >&2
    exit 1
  fi

  key_fingerprint=$(gpg --with-colons --list-keys -q "${KEY_IDENTIFIER}" | awk -F: '/^pub/{flag=1} flag && /^fpr/ {print $10; exit}')

  if [[ -z "${key_fingerprint}" ]]; then
    echo "'${KEY_IDENTIFIER}' fingerprint is absent, abort the operation." >&2
    exit 1
  fi

  echo "${key_fingerprint}:6:" | gpg --import-ownertrust

  echo "Imported key_file: ${key_file} with fingerprint: ${key_fingerprint}"
}

export-keys() {
  check-keypair-param

  check-default-user-mode

  if ! gpg --list-keys --with-colons -q | grep -q "^uid:.*${KEY_IDENTIFIER}"; then
    echo "GPG key with identifier '$KEY_IDENTIFIER' is not exists." >&2
    exit 1
  fi

  key_fingerprint=$(gpg --with-colons --list-keys -q "${KEY_IDENTIFIER}" | awk -F: '/^pub/{flag=1} flag && /^fpr/ {print $10; exit}')

  if [[ -z "${key_fingerprint}" ]]; then
    echo "'${KEY_IDENTIFIER}' fingerprint is absent, abort the operation." >&2
    exit 1
  fi

  case "${OPS_KEYS_MOD}" in
  "${OPS_KEYS_MOD_PUB}")
    export-pub-key "${key_fingerprint}"
    ;;
  "${OPS_KEYS_MOD_PRIV}")
    export-priv-key "${key_fingerprint}"
    ;;
  "${OPS_KEYS_MOD_PAIR}")
    export-priv-key "${key_fingerprint}"
    export-pub-key "${key_fingerprint}"
    ;;
  *)
    echo "The OPS_KEYS_MOD: ${OPS_KEYS_MOD} is not supported!"
    exit 1
    ;;
  esac

  echo "Export key with fingerprint: ${key_fingerprint}"
}

export-priv-key() {
  local key_fingerprint="${1-}"

  gpg --no-tty --batch --yes --export-secret-keys --armor "${key_fingerprint}" >"${PRIV_KEY_FILE}"
  echo "Export gpg priv key for ${key_fingerprint}."
}

export-pub-key() {
  local key_fingerprint="${1-}"

  gpg --no-tty --batch --yes --export --armor "${key_fingerprint}" >"${PUB_KEY_FILE}"
  echo "Export gpg pub key for ${key_fingerprint}."
}

remove-keypub() {
  OPS_KEYS_MOD="${OPS_KEYS_MOD_PUB}"
  remove-keys

  echo "Removed key pub for ${KEY_IDENTIFIER}."
}

remove-keypriv() {
  OPS_KEYS_MOD="${OPS_KEYS_MOD_PRIV}"
  remove-keys

  echo "Removed key pub for ${KEY_IDENTIFIER}."
}

remove-keys() {
  check-keypair-param

  check-default-user-mode

  if ! gpg --list-keys --with-colons -q | grep -q "^uid:.*${KEY_IDENTIFIER}"; then
    echo "GPG key with identifier '$KEY_IDENTIFIER' is not exists."
    return 0
  fi

  key_fingerprint=$(gpg --with-colons --list-keys -q "${KEY_IDENTIFIER}" | awk -F: '/^pub/{flag=1} flag && /^fpr/ {print $10; exit}')

  if [[ -z "${key_fingerprint}" ]]; then
    echo "'${KEY_IDENTIFIER}' fingerprint is absent, abort the operation." >&2
    exit 1
  fi

  case "${OPS_KEYS_MOD}" in
  "${OPS_KEYS_MOD_PUB}")
    remove-pub-key "${key_fingerprint}"
    ;;
  "${OPS_KEYS_MOD_PRIV}")
    remove-priv-key "${key_fingerprint}"
    ;;
  "${OPS_KEYS_MOD_PAIR}")
    remove-priv-key "${key_fingerprint}"
    remove-pub-key "${key_fingerprint}"
    ;;
  *)
    echo "The OPS_KEYS_MOD: ${OPS_KEYS_MOD} is not supported!"
    exit 1
    ;;
  esac

  echo "Removed key with fingerprint: ${key_fingerprint}"

}

remove-pub-key() {
  local key_fingerprint="${1-}"
  gpg --no-tty --batch --yes --delete-key "${key_fingerprint}"

  echo "removed gpg pub key for ${key_fingerprint}."
}

remove-priv-key() {
  local key_fingerprint="${1-}"
  gpg --no-tty --batch --yes --delete-secret-key "${key_fingerprint}"
  echo "removed gpg priv key for ${key_fingerprint}."
}

check-keypair-param() {
  if [[ -z "${KEY_NAME}" ]]; then
    echo "KEY_NAME param is empty!" >&2
    exit 1
  fi

  if [[ -z "${KEY_EMAIL}" ]]; then
    echo "KEY_EMAIL param is empty!" >&2
    exit 1
  fi

  if [[ -z "${KEY_COMMENT}" ]]; then
    echo "KEY_COMMENT param is empty!" >&2
    exit 1
  fi
}
