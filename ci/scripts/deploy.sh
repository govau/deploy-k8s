#!/bin/bash

set -euo pipefail
set -v

: "${ENV_NAME:?Need to set ENV_NAME e.g. k}"
: "${JUMPBOX_SSH_PORT:?Need to set JUMPBOX_SSH_PORT}"
: "${JUMPBOX_SSH_KEY:?Need to set JUMPBOX_SSH_KEY}"
: "${SSH_CA:?Need to set SSH_CA}"

PATH_TO_DEPLOY_KOPS=${PWD}/deploy-kops.git
JUMPBOX=bosh-jumpbox.${ENV_NAME}.cld.gov.au
PATH_TO_KEY=${PWD}/jumpbox.pem

# Add DTA CA as cert authority for jumpboxes
mkdir -p $HOME/.ssh
cat <<EOF >> $HOME/.ssh/known_hosts
@cert-authority *.cld.gov.au $SSH_CA
EOF

# Create the private key for the jumpbox
echo "${JUMPBOX_SSH_KEY}">${PATH_TO_KEY}
chmod 600 ${PATH_TO_KEY}

cd "${PATH_TO_DEPLOY_KOPS}/installer"

ansible-playbook \
  --private-key=${PATH_TO_KEY} \
  --ssh-common-args="-oBatchMode=yes" \
  -i ${JUMPBOX}:${JUMPBOX_SSH_PORT}, playbook.yml

ssh -oBatchMode=yes -i ${PATH_TO_KEY} -p ${JUMPBOX_SSH_PORT} ec2-user@${JUMPBOX} \
  "[[ -d kops ]] && kops/bin/deploy.sh"
