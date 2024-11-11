KEY_TYPE="RSA"
KEY_LENGTH="2048"

REMOVE_KEYS_MOD_PUB="pub"
REMOVE_KEYS_MOD_PRIV="priv"
REMOVE_KEYS_MOD_PAIR="pair"

REMOVE_KEYS_MOD=""

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
  REMOVE_KEYS_MOD="${REMOVE_KEYS_MOD_PAIR}"
  remove-keys

  echo "Removed key pair for ${KEY_IDENTIFIER}."
}

remove-keypub() {
  REMOVE_KEYS_MOD="${REMOVE_KEYS_MOD_PUB}"
  remove-keys

  echo "Removed key pub for ${KEY_IDENTIFIER}."
}

remove-keypriv() {
  REMOVE_KEYS_MOD="${REMOVE_KEYS_MOD_PRIV}"
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

  case "${REMOVE_KEYS_MOD}" in
  "${REMOVE_KEYS_MOD_PUB}")
    remove-pub-key "${key_fingerprint}"
    ;;
  "${REMOVE_KEYS_MOD_PRIV}")
    remove-priv-key "${key_fingerprint}"
    ;;
  "${REMOVE_KEYS_MOD_PAIR}")
    remove-priv-key "${key_fingerprint}"
    remove-pub-key "${key_fingerprint}"
    ;;
  *)
    echo "The REMOVE_KEYS_MOD: ${REMOVE_KEYS_MOD} is not supported!"
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
