# CircleCI docker image to run within
FROM circleci/python:3.9.7
# Base image uses "circleci", to avoid using `sudo` run as root user and reset
# at the end.
USER root

# Golang env flags that limit parallel execution
# The golang default is to use the max CPUs or default to 36.
# In CircleCI 2.0 the max CPUs is 2 but golang can't get this from the environment so it defaults to 36
# This can cause build flakiness for larger projects. Setting a value here that can be overridden during execution
# may prevent others from experiencing this same problem.
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
ARG GO_VERSION=1.17
ARG GO_SHA256SUM=6bf89fc4f5ad763871cf7eac80a2d594492de7a818303283f1366a7f6a30372d
RUN set -ex && cd ~ \
    && curl -sSLO https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
    && [ $(sha256sum go${GO_VERSION}.linux-amd64.tar.gz | cut -f1 -d' ') = ${GO_SHA256SUM} ] \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && ln -s /usr/local/go/bin/* /usr/local/bin \
    && rm -vf go${GO_VERSION}.linux-amd64.tar.gz

#install goreleaser
ARG GORELEASER_VERSION=0.175.0
ARG GORELEASER_SHA256SUM=f60d1d7c6bec78a6b8613b6e07c4259c81c5d04d263d420bc3e97b507145e065
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/goreleaser_Linux_x86_64.tar.gz \
    && [ $(sha256sum goreleaser_Linux_x86_64.tar.gz | cut -f1 -d' ') = ${GORELEASER_SHA256SUM} ] \
    && mkdir -p goreleaser_Linux_x86_64 \
    && tar xf goreleaser_Linux_x86_64.tar.gz -C goreleaser_Linux_x86_64 \
    && chown root:root goreleaser_Linux_x86_64/goreleaser \
    && mv goreleaser_Linux_x86_64/goreleaser /usr/local/bin \
    && rm -vrf goreleaser_Linux_x86_64 goreleaser_Linux_x86_64.tar.gz

# install shellcheck
ARG SHELLCHECK_VERSION=0.7.2
ARG SHELLCHECK_SHA256SUM=70423609f27b504d6c0c47e340f33652aea975e45f312324f2dbf91c95a3b188
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz \
    && [ $(sha256sum shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz | cut -f1 -d' ') = ${SHELLCHECK_SHA256SUM} ] \
    && tar xvfa shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz \
    && mv shellcheck-v${SHELLCHECK_VERSION}/shellcheck /usr/local/bin \
    && chown root:root /usr/local/bin/shellcheck \
    && rm -vrf shellcheck-v${SHELLCHECK_VERSION} shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz

# install terraform
ARG TERRAFORM_VERSION=1.0.5
RUN set -ex && cd ~ \
    && curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig \
    && curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && sha256sum -c terraform_${TERRAFORM_VERSION}_SHA256SUMS --ignore-missing \
    && unzip -o -d /usr/local/bin -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && rm -vf terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig

# install terraform-docs
ARG TERRAFORM_DOCS_VERSION=0.15.0
ARG TERRAFORM_DOCS_SHA256SUM=e0b399d9dc2eb97853a7e12f1ae678e7160cae4c811646ce70169a8d611f6cf9
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/segmentio/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz \
    && [ $(sha256sum terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz | cut -f1 -d' ') = ${TERRAFORM_DOCS_SHA256SUM} ] \
    && mkdir terraform-docs \
    && tar -C terraform-docs -xzf terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz \
    && chown root:root terraform-docs/terraform-docs \
    && mv terraform-docs/terraform-docs /usr/local/bin \
    && rm -vrf terraform-docs terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz

# install tfsec
ARG TFSEC_VERSION=0.58.4
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
ARG AWSCLI_VERSION=2.2.30
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


# Finally, reset to expected user.
USER circleci
