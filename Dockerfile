FROM python:3.11-slim-bullseye

RUN apt update && apt install gnupg curl unzip -y

# Golang env flags that limit parallel execution
# The golang default is to use the max CPUs or default to 36.
ENV GOFLAGS=-p=4

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

# install go
ARG GO_VERSION=1.20.4
ARG GO_SHA256SUM=698ef3243972a51ddb4028e4a1ac63dc6d60821bf18e59a807e051fee0a385bd
RUN set -ex && cd ~ \
    && curl -sSLO https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && [ $(sha256sum go${GO_VERSION}.linux-amd64.tar.gz | cut -f1 -d' ') = ${GO_SHA256SUM} ] \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && ln -s /usr/local/go/bin/* /usr/local/bin \
    && rm -vf go${GO_VERSION}.linux-amd64.tar.gz

#install goreleaser
ARG GORELEASER_VERSION=1.18.2
ARG GORELEASER_SHA256SUM=811e0c63e347f78f3c8612a19ca8eeb564eb45f0265ce3f38aec39c8fdbcfa10
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/goreleaser_Linux_x86_64.tar.gz \
    && [ $(sha256sum goreleaser_Linux_x86_64.tar.gz | cut -f1 -d' ') = ${GORELEASER_SHA256SUM} ] \
    && mkdir -p goreleaser_Linux_x86_64 \
    && tar xf goreleaser_Linux_x86_64.tar.gz -C goreleaser_Linux_x86_64 \
    && chown root:root goreleaser_Linux_x86_64/goreleaser \
    && mv goreleaser_Linux_x86_64/goreleaser /usr/local/bin \
    && rm -vrf goreleaser_Linux_x86_64 goreleaser_Linux_x86_64.tar.gz

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

# install circleci cli
ARG CIRCLECI_CLI_VERSION=0.1.15848
ARG CIRCLECI_CLI_SHA256SUM=28b01acb8e456cb652ed944f0302eadbf5543c9479640464c0993fb9f2cdf177
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/CircleCI-Public/circleci-cli/releases/download/v${CIRCLECI_CLI_VERSION}/circleci-cli_${CIRCLECI_CLI_VERSION}_linux_amd64.tar.gz \
    && [ $(sha256sum circleci-cli_${CIRCLECI_CLI_VERSION}_linux_amd64.tar.gz | cut -f1 -d' ') = ${CIRCLECI_CLI_SHA256SUM} ] \
    && tar xzf circleci-cli_${CIRCLECI_CLI_VERSION}_linux_amd64.tar.gz \
    && mv circleci-cli_${CIRCLECI_CLI_VERSION}_linux_amd64/circleci /usr/local/bin \
    && chmod 755 /usr/local/bin/circleci \
    && chown root:root /usr/local/bin/circleci \
    && rm -vrf circleci-cli_${CIRCLECI_CLI_VERSION}_linux_amd64 circleci-cli_${CIRCLECI_CLI_VERSION}_linux_amd64.tar.gz

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
