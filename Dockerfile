FROM ubuntu:18.04

RUN \
  export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get -y install \
    apt-transport-https \
    awscli \
    bash-completion \
    curl \
    dnsutils \
    gnupg \
    jq \
    less \
    openssh-client \
    python3-pip \
    unzip \
    vim \
    wget \
  && rm -rf /var/lib/apt/lists/* \
  && pip3 install yq \
  && echo "source /etc/profile.d/bash_completion.sh" >> /root/.bashrc \
  && echo "alias k=kubectl" >> /root/.bashrc \
  && ln -fs /usr/share/zoneinfo/Australia/Sydney /etc/localtime

ENV KOPS_VERSION="1.10.0"
ENV KUBECTL_VERSION "1.12.1"
ENV HELM_VERSION="v2.11.0"
ENV TERRAFORM_VERSION="0.11.8"

RUN \
  curl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl > /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl \
  && echo "source <(kubectl completion bash)" >> /root/.bashrc

RUN \
  curl -L https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 > /usr/local/bin/kops \
  && chmod +x /usr/local/bin/kops

RUN \
  HELM_FILENAME=helm-${HELM_VERSION}-linux-amd64.tar.gz \
  && curl -o /tmp/${HELM_FILENAME} https://storage.googleapis.com/kubernetes-helm/${HELM_FILENAME} \
  && tar -zxvf /tmp/${HELM_FILENAME} -C /tmp \
  && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
  && rm -rf /tmp/linux-amd64 "/tmp/${HELM_FILENAME}"

RUN \
  curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > /tmp/terraform.zip \
  && unzip /tmp/terraform.zip terraform -d /usr/local/bin \
  && rm /tmp/terraform.zip

CMD ["/bin/bash"]
