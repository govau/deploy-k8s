#!/usr/bin/env bash

set -euxo pipefail

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

ENV_NAME="$(sdget env.cld.internal name)"
DNS_ZONE="$(sdget dns.cld.internal private-zone-id)"
VPC_ID="$(sdget net.cld.internal vpc-id)"
VPC_CIDR="$(sdget net.cld.internal vpc-cidr)"
NAT_GATEWAY_A="$(sdget 0.public_nat.net.cld.internal id)"
NAT_GATEWAY_B="$(sdget 1.public_nat.net.cld.internal id)"
NAT_GATEWAY_C="$(sdget 2.public_nat.net.cld.internal id)"

KOPS_CLUSTER_NAME_PREFIX="$(sdget kops.cld.internal cluster-name-prefix)"
KOPS_CLUSTER_NAME="${ENV_NAME}.cld.gov.au"
if [[ ${KOPS_CLUSTER_NAME_PREFIX} != "" ]]; then
  KOPS_CLUSTER_NAME="${KOPS_CLUSTER_NAME_PREFIX}.${KOPS_CLUSTER_NAME}"
fi
export KOPS_CLUSTER_NAME # so that kops picks it up without --name

PRIVATE_SUBNET_CIDR_A="$(sdget kops.cld.internal private-subnet-cidr-a)"
PRIVATE_SUBNET_CIDR_B="$(sdget kops.cld.internal private-subnet-cidr-b)"
PRIVATE_SUBNET_CIDR_C="$(sdget kops.cld.internal private-subnet-cidr-c)"
UTILITY_SUBNET_CIDR_A="$(sdget kops.cld.internal utility-subnet-cidr-a)"
UTILITY_SUBNET_CIDR_B="$(sdget kops.cld.internal utility-subnet-cidr-b)"
UTILITY_SUBNET_CIDR_C="$(sdget kops.cld.internal utility-subnet-cidr-c)"

export KOPS_STATE_STORE="$(sdget kops.cld.internal state-store)"

# Create this cluster's config from the template
kops toolbox template \
  --template "${SCRIPTPATH}/../cluster.template.yml" \
  --set-string "kopsStateStore=${KOPS_STATE_STORE}" \
  --set-string "dnsZone=${DNS_ZONE}" \
  --set-string "vpcId=${VPC_ID}" \
  --set-string "vpcCidr=${VPC_CIDR}" \
  --set-string "privateSubnetCidrA=${PRIVATE_SUBNET_CIDR_A}" \
  --set-string "privateSubnetCidrB=${PRIVATE_SUBNET_CIDR_B}" \
  --set-string "privateSubnetCidrC=${PRIVATE_SUBNET_CIDR_C}" \
  --set-string "utilitySubnetCidrA=${UTILITY_SUBNET_CIDR_A}" \
  --set-string "utilitySubnetCidrB=${UTILITY_SUBNET_CIDR_B}" \
  --set-string "utilitySubnetCidrC=${UTILITY_SUBNET_CIDR_C}" \
  --set-string "natGatewayA=${NAT_GATEWAY_A}" \
  --set-string "natGatewayB=${NAT_GATEWAY_B}" \
  --set-string "natGatewayC=${NAT_GATEWAY_C}" \
  --output "${SCRIPTPATH}/../cluster.yml"

# For now just use the same ssh key for each cluster in this env

# Create a new cluster and overwrite it with our config, or just overwrite it
kops create cluster \
    --zones ap-southeast-2a,ap-southeast-2b,ap-southeast-2c \
    --master-zones ap-southeast-2a,ap-southeast-2b,ap-southeast-2c \
    --master-count=3 \
    --dns private \
    --dns-zone "${DNS_ZONE}" \
    --ssh-public-key "${SCRIPTPATH}/../k8s-key.pub" \
    && kops replace -f ${SCRIPTPATH}/../cluster.yml \
    || kops replace -f ${SCRIPTPATH}/../cluster.yml --force

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
