#!/usr/bin/env bash

set -eux

TARGET=${TARGET:-m-cld}
PIPELINE=kops
fly validate-pipeline --config pipeline.yml

GEN_CREDS="$(./gen-creds.sh)"

fly -t ${TARGET} set-pipeline \
  --config pipeline.yml \
  --pipeline "${PIPELINE}" \
  -l <(echo "${GEN_CREDS}")

# Check all resources for errors
RESOURCES="$(fly -t "${TARGET}" get-pipeline -p "${PIPELINE}" | yq -r '.resources[].name')"
for RESOURCE in $RESOURCES; do
  fly -t ${TARGET} check-resource --resource "${PIPELINE}/${RESOURCE}"
done

fly -t ${TARGET} unpause-pipeline -p ${PIPELINE}
