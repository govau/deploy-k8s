# deploy-k8s

_This is still a work in progress and is likely not production ready_

Our kubernetes is deployed with [kops](https://github.com/kubernetes/kops).

## Prerequisites

### AWS access

kops needs AWS access. Our recommended way is to use aws profiles configured in ~/.aws files, for example:

AWS_PROFILE=k-cld

```
$ cat ~/.aws/credentials
[default]
# add keys for your @digital.gov.au iam user in the AWS organisation account
aws_access_key_id = AKI...
aws_secret_access_key =
region = ap-southeast-2

[k-cld]
source_profile = default
role_arn = arn:aws:iam::123456789012:role/the-role
```

To use this `k-cld` profile, you would need to run `export AWS_PROFILE=k-cld` before running kops/aws comands. Additionally, kops uses the Go AWS SDK, which [needs the environment variable](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/#hdr-Sessions_from_Shared_Config) `AWS_SDK_LOAD_CONFIG` set to read from this configuration file.

### Terraform secrets

There are two files in each env which must be added before terraform will work:
- `terraform/env/secret-backend.cfg`
- `terraform/env/secret.auto.tfvars`

See the samples for each as to how to configure them.

You will need to specify the backend config when running  terraform init. e.g.
```
cd terraform/env/k-cld
terraform init -backend-config=../secret-backend.cfg
```

## Dockerfile quick start

You can use the included `Dockerfile` and `rundocker.sh` to quickly get a terminal running with the same versions of the cli tools as the concourse pipeline and with the necessary environment variables.

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
pushd terraform/env/${ENV_NAME}-cld
  export KOPS_STATE_STORE="s3://$(terraform output kops_cluster_state_bucket_id)"
popd
```

You should then be able to run kops commands such as `kops get clusters`.

## Using kubectl

To run kubectl commands, you need a kubectl config file. `kops create/update cluster` will write out `.kube/config`, allowing you to run kubectl. Since this contains secrets, it is not checked in. To recreate it for yourself on your machine, run `kops export kubecfg <cluster name>`.

Change targeted cluster with `kubectl config use-context <cluster-name>`.

## Using the cluster template

We use a [cluster template](https://github.com/kubernetes/kops/blob/master/docs/cluster_template.md) to ensure the cluster config can be deployed and tested in a CI pipline.

To create your own cluster:

```
ENV_NAME=k \
  KOPS_CLUSTER_NAME=foo.k.cld.gov.au \
  ./scripts/deploy-cluster.sh

# wait a while

# Kops will have set your kubectl config to use the cluster,
# so you can now use kubectl commands on it
kubectl cluster-info

kubectl get pods

# Delete it when you're done
kops delete cluster --name foo.k.cld.gov.au --yes
```

## Modifying the cluster template using `kops create cluster`

If you want to run `kops create cluster` and make that the new cluster template, or even create your own cluster from scratch without using the template, the rough steps are:

```
KOPS_CLUSTER_NAME=newcluster.k.cld.gov.au

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
    --ssh-public-key ./terraform/env/k-cld/k-cld-k8s-key.pub \
    --yes

# Maybe edit the cluster in $EDITOR if you want
kops edit cluster

# Export the new cluster to yml
kops get -o yaml > ${KOPS_CLUSTER_NAME}.yml

# You can then diff this file against `cluster.template.yml` and make changes
```
