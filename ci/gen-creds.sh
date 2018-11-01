#!/usr/bin/env bash

# Fetches the credentials needed by `fly set-pipeline`
# and dumps them to stdout

set -euo pipefail

JUMPBOX_SSH_KEY="$(gpg --decrypt $PATH_TO_OPS/sekrets/concourse/root-concourse.pem.gpg)"

# We assume the SSH_CA and JUMPBOX_SSH_PORT is in our env.
# TODO Can we get it from sekrets?
: "${SSH_CA:?Need to set SSH_CA}"
: "${JUMPBOX_SSH_PORT:?Need to set JUMPBOX_SSH_PORT}"

# You can put DEPLOY_KEY in your env, otherwise this will create one and upload to github
if [[ -z "${DEPLOY_KEY}" ]]; then

  : "${GITHUB_USER:?Need to set GITHUB_USER}"
  : "${GITHUB_PERSONAL_ACCESS_TOKEN:?Need to set GITHUB_PERSONAL_ACCESS_TOKEN}"

  CREDS="${GITHUB_USER}:${GITHUB_PERSONAL_ACCESS_TOKEN}"
  URL=https://api.github.com
  KEY_NAME=concourse.m.cld.gov.au

  DEPLOY_KEY_IDS="$(curl -u $CREDS $URL/repos/govau/deploy-kops/keys | jq -r .[].id)"

  # Delete old key if we find it
  for deploy_key_id in $DEPLOY_KEY_IDS; do
    deploy_key_title="$(curl -u $CREDS $URL/repos/govau/deploy-kops/keys/${deploy_key_id} | jq -r .title)"
    if [[ $deploy_key_title == ${KEY_NAME} ]]; then
      curl \
        -X DELETE \
        -u $CREDS \
        $URL/repos/govau/deploy-kops/keys/${deploy_key_id}
    fi
  done

  #Create new key
  rm -f ./deploy-key*
  ssh-keygen -t rsa -C "concourse.m.cld.gov.au" -b 4096 -f deploy-key -N '' >&2

  DEPLOY_KEY="$(cat ./deploy-key)"
  DEPLOY_KEY_PUB="$(cat ./deploy-key.pub)"
  rm -f ./deploy-key*

  curl \
    -u $CREDS \
    -H "Content-Type: application/json" \
    -d@- \
    $URL/repos/govau/deploy-kops/keys >&2 <<EOF
    {
      "title": "${KEY_NAME}",
      "key":"${DEPLOY_KEY_PUB}",
      "read_only": true
    }
EOF
fi

# Now output the creds as yml

cat <<EOF
deploy_kops_git_deploy_key: |
$(echo "${DEPLOY_KEY}" | sed 's/^/  /')

jumpbox_ssh_port: ${JUMPBOX_SSH_PORT}

jumpbox_ssh_key: |
$(echo "${JUMPBOX_SSH_KEY}" | sed 's/^/  /')

ssh_ca: |
$(echo "${SSH_CA}" | sed 's/^/  /')
EOF
