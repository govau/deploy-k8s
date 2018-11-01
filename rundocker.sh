#!/usr/bin/env bash

set -e

: "${ENV_NAME:?Need to set your ENV_NAME}"

echo Building the image
docker build . --tag cga-kubernetes

echo Starting a container with the image. It will be removed when you exit.
docker run -it --rm \
  -v $PWD:/workspace -w /workspace \
  -v $HOME/.aws:/root/.aws \
  -e "AWS_PROFILE=${ENV_NAME}-cld" \
  -e "AWS_REGION=ap-southeast-2" \
  -e "AWS_SDK_LOAD_CONFIG=1" \
  -e "KUBECONFIG=/workspace/.kube/${ENV_NAME}/config" \
  cga-kubernetes

# Setting `KUBECONFIG` to a file in the workspace is a convenience so it
# persists between container restarts.
