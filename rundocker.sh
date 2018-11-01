#!/usr/bin/env bash

set -e

: "${ENV_NAME:?Need to set your ENV_NAME}"

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# Go use the kops cluster state for this env
pushd $SCRIPTPATH/terraform/env/${ENV_NAME}-cld
  KOPS_STATE_STORE="s3://$(terraform output kops_cluster_state_bucket_id)"
popd

echo Building the image
docker build . --tag cga-kubernetes

echo Starting a container with the image. It will be removed when you exit.
docker run -it --rm \
  -v $PWD:/workspace -w /workspace \
  -v $HOME/.aws:/root/.aws \
  -e "AWS_PROFILE=${ENV_NAME}-cld" \
  -e "AWS_REGION=ap-southeast-2" \
  -e "AWS_SDK_LOAD_CONFIG=1" \
  -e "KOPS_STATE_STORE=${KOPS_STATE_STORE}" \
  -e "KUBECONFIG=/workspace/.kube/${ENV_NAME}/config" \
  cga-kubernetes

# Setting `KUBECONFIG` to a file in the workspace is a convenience so it
# persists between container restarts.
