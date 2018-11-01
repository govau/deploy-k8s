#!/usr/bin/env bash

set -eux

: "${KOPS_CLUSTER_NAME:?Need to set KOPS_CLUSTER_NAME e.g. foo.k.cld.gov.au}"
: "${ENV_NAME:?Need to set ENV_NAME e.g. k}"

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

if [ -z ${KOPS_STATE_STORE+x} ]; then
  # KOPS_STATE_STORE is not set, so fetch it from terraform
  pushd $SCRIPTPATH/../terraform/env/${ENV_NAME}-cld
    KOPS_STATE_STORE=$(terraform output kops_cluster_state_bucket_domain_name)
  popd
fi

# Create this cluster's config from the template
kops toolbox template \
  --template ./cluster.template.yml \
  --set-string "kopsStateStore=${KOPS_STATE_STORE}" \
  --name "${KOPS_CLUSTER_NAME}" \
  --output ./cluster-${ENV_NAME}.yml

# For now just use the same ssh key for each cluster in this env

# Create a new cluster and overwrite it with our config, or just overwrite it
kops create cluster \
    --zones ap-southeast-2a,ap-southeast-2b,ap-southeast-2c \
    --master-zones ap-southeast-2a,ap-southeast-2b,ap-southeast-2c \
    --master-count=3 \
    --ssh-public-key "${SCRIPTPATH}/../terraform/env/${ENV_NAME}-cld/${ENV_NAME}-cld-k8s-key.pub" \
    && kops replace -f ./cluster-${ENV_NAME}.yml \
    || kops replace -f ./cluster-${ENV_NAME}.yml --force

kops update cluster --yes

# Wait 15 mins for cluster to be up
max_wait=900
while [[ $max_wait -gt 0 ]]; do
    kops validate cluster && break || sleep 30
    max_wait=$(($max_wait - 30))
    echo "Waited 30 seconds. Still waiting max. $max_wait"
done

if [[ $max_wait -le 0 ]]; then
    echo "Timeout: cluster did not validate after 15 minutes"
    exit 1
fi

kops rolling-update cluster --yes
