FROM python:3.11-slim-bullseye

RUN apt update && apt dist-upgrade -y && apt install gnupg curl unzip git -y

# Import signing keys
COPY signing_keys /tmp/signing_keys
RUN set -ex && cd ~ \
    && for key in /tmp/signing_keys/*.pub; do gpg --import $key; done

# install pip packages
ARG CACHE_PIP
ADD ./requirements.txt /tmp/requirements.txt
RUN set -ex && cd ~ \
    && pip install -r /tmp/requirements.txt --no-cache-dir --disable-pip-version-check \
    && rm -vf /tmp/requirements.txt

# install terraform
ARG TERRAFORM_VERSION=1.4.6
RUN set -ex && cd ~ \
    && curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig \
    && curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && sha256sum -c terraform_${TERRAFORM_VERSION}_SHA256SUMS --ignore-missing \
    && unzip -o -d /usr/local/bin -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && rm -vf terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig

# install terraform-docs
ARG TERRAFORM_DOCS_VERSION=0.16.0
ARG TERRAFORM_DOCS_SHA256SUM=328c16cd6552b3b5c4686b8d945a2e2e18d2b8145b6b66129cd5491840010182
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz \
    && [ $(sha256sum terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz | cut -f1 -d' ') = ${TERRAFORM_DOCS_SHA256SUM} ] \
    && mkdir terraform-docs \
    && tar -C terraform-docs -xzf terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz \
    && chown root:root terraform-docs/terraform-docs \
    && mv terraform-docs/terraform-docs /usr/local/bin \
    && rm -vrf terraform-docs terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz

# install tfsec
ARG TFSEC_VERSION=1.28.1
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/tfsec/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 \
    && curl -sSLO https://github.com/tfsec/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64.D66B222A3EA4C25D5D1A097FC34ACEFB46EC39CE.sig \
    && gpg --verify tfsec-linux-amd64.D66B222A3EA4C25D5D1A097FC34ACEFB46EC39CE.sig tfsec-linux-amd64 \
    && chmod 755 tfsec-linux-amd64 \
    && mv tfsec-linux-amd64 /usr/local/bin/tfsec \
    && rm -vf tfsec-linux-amd64.D66B222A3EA4C25D5D1A097FC34ACEFB46EC39CE.sig

# install awscliv2, disable default pager (less)
ENV AWS_PAGER=""
ARG AWSCLI_VERSION=2.11.18
RUN set -ex && cd ~ \
    && curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o awscliv2.zip \
    && curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip.sig" -o awscliv2.sig \
    && gpg --verify awscliv2.sig awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install --update \
    && aws --version \
    && rm -vrf awscliv2.zip awscliv2.sig aws

# apt-get all the things
# Notes:
# - Add all apt sources first
# - groff and less required by AWS CLI
ARG CACHE_APT
RUN set -ex && cd ~ \
    && apt-get update \
    && : Install apt packages \
    && apt-get -qq -y install --no-install-recommends apt-transport-https less groff lsb-release \
    && : Cleanup \
    && apt-get clean \
    && rm -vrf /var/lib/apt/lists/*
