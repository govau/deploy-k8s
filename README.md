# deploy-kops

_This is still a work in progress and is likely not production ready_

Our kubernetes is deployed with [kops](https://github.com/kubernetes/kops).

## Prerequisites

### AWS access

#### Inside AWS

The jumpbox in each environment (x.cld.gov.au) has an EC2 IAM profile which allows us to run kops on the jumpbox.

#### Outside of AWS

kops needs AWS access. Our recommended way is to use aws profiles configured in ~/.aws files, for example:

```bash

$ cat ~/.aws/credentials
[default]
# add keys for your @digital.gov.au iam user in the root/parent AWS organisation account
aws_access_key_id = AKI...
aws_secret_access_key =
region = ap-southeast-2

[k-cld]
source_profile = default
role_arn = arn:aws:iam::123456789012:role/the-role
```

To use this `k-cld` profile, you would need to run `export AWS_PROFILE=k-cld` before running kops/aws comands. Additionally, kops uses the Go AWS SDK, which [needs the environment variable](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/#hdr-Sessions_from_Shared_Config) `AWS_SDK_LOAD_CONFIG` set to read from this configuration file.

### Kops

We use a terraform module to setup the prerequisites and integrate with our
existing environments: https://github.com/govau/cga-kops-tf

## Deploying on cloud.gov.au

Run the ansible playbook, and then the deploy script.

```bash
ENV_NAME=k

cd ${PATH_TO_REPOS}/deploy-kops/installer

ansible-playbook -i bosh-jumpbox.${ENV_NAME}.cld.gov.au, playbook.yml

ssh bosh-jumpbox.$ENV_NAME.cld.gov.au kops/bin/deploy.sh
```

## Dockerfile quick start

You can use the included `Dockerfile` and `rundocker.sh` to quickly get a terminal running with kops and other useful things, and with the necessary environment variables.

For example:

```
ENV_NAME=k ./rundocker.sh
```

Commands like `kops get clusters` should now just work.

## Using kops

All the kops configuration is saved in the `KOPS_STATE_STORE` s3 bucket. We use a separate bucket for each environment.

Before you can run kops commands, you will need to have the `KOPS_STATE_STORE` environment variable set correctly for the environment you are targeting.

You can set this with
```
ENV_NAME=k
pushd ${PATH_TO_OPS}/terraform/env/${ENV_NAME}-cld
  export KOPS_STATE_STORE="s3://$(terraform output kops_state_store)"
popd
```

You should then be able to run kops commands such as `kops get clusters`.

## Using kubectl

To run kubectl commands, you need a kubectl config file. `kops create/update cluster` will write out `.kube/config`, allowing you to run kubectl. Since this contains secrets, it is not checked in. To recreate it for yourself on your machine, run `kops export kubecfg <cluster name>`.

Change targeted cluster with `kubectl config use-context <cluster-name>`.

## Create a test cluster

To create your own cluster to experiment with, at the moment its easiest to do so in your own AWS account.

Follow the kops doco for [setting up your environment](https://github.com/kubernetes/kops/blob/master/docs/aws.md#setup-your-environment)

Then you can do stuff like:

```bash
NAME=mycluster.x.cld.gov.au

kops create cluster \
    --master-count 3 \
    --node-count 2 \
    --zones ap-southeast-2a,ap-southeast-2b \
    --master-zones ap-southeast-2a,ap-southeast-2b,ap-southeast-2c \
    --node-size t2.medium \
    --master-size t2.medium \
    --topology private \
    --networking kopeio-vxlan \
    --encrypt-etcd-storage \
    --ssh-public-key ./somekey.pub \
    --name ${NAME} \
    --yes

# Maybe edit the cluster in $EDITOR if you want
kops edit cluster ${NAME}

# Build the cluster
kops update cluster ${NAME} --yes

# Delete it when you're done
kops delete cluster --name ${NAME} --yes
```

## Using the cluster template

We use a [cluster template](https://github.com/kubernetes/kops/blob/master/docs/cluster_template.md) to ensure the cluster config can be deployed and tested in a CI pipeline.

If you want to run `kops create cluster` and make that the new cluster template, or even create your own cluster from scratch without using the template, the rough steps are:

```
export KOPS_CLUSTER_NAME=newcluster.k.cld.gov.au

kops create cluster \
    --master-count 3 \
    --node-count 2 \
    --zones ap-southeast-2a,ap-southeast-2b \
    --master-zones ap-southeast-2a,ap-southeast-2b,ap-southeast-2c \
    --node-size t2.medium \
    --master-size t2.medium \
    --topology private \
    --networking kopeio-vxlan \
    --encrypt-etcd-storage \
    --ssh-public-key ./somekey.pub \
    --yes

# Maybe edit the cluster in $EDITOR if you want
kops edit cluster

# Export the new cluster to yml
kops get -o yaml > ${KOPS_CLUSTER_NAME}.yml

# You can then diff this file against `cluster.template.yml` and make changes
```
