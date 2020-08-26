
# CircleCI docker image to run within
FROM circleci/python:3.8
# Base image uses "circleci", to avoid using `sudo` run as root user
USER root

# Golang env flags that limit parallel execution
# The golang default is to use the max CPUs or default to 36.
# In CircleCI 2.0 the max CPUs is 2 but golang can't get this from the environment so it defaults to 36
# This can cause build flakiness for larger projects. Setting a value here that can be overridden during execution
# may prevent others from experiencing this same problem.
ENV GOFLAGS=-p=4


# install pip packages
ARG CACHE_PIP
ADD ./requirements.txt /tmp/requirements.txt
RUN set -ex && cd ~ \
    && pip install -r /tmp/requirements.txt --no-cache-dir --disable-pip-version-check \
    && rm -vf /tmp/requirements.txt

# install go
ARG GO_VERSION=1.15
ARG GO_SHA256SUM=2d75848ac606061efe52a8068d0e647b35ce487a15bb52272c427df485193602
RUN set -ex && cd ~ \
    && curl -sSLO https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
    && [ $(sha256sum go${GO_VERSION}.linux-amd64.tar.gz | cut -f1 -d' ') = ${GO_SHA256SUM} ] \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && ln -s /usr/local/go/bin/* /usr/local/bin \
    && rm -v go${GO_VERSION}.linux-amd64.tar.gz

# install go-bindata
ARG GO_BINDATA_VERSION=3.21.0
ARG GO_BINDATA_SHA256SUM=87fc875f5beb928c33ae321147ed9b1ca52e15afe5606500f59eaec6206eeab5
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/kevinburke/go-bindata/releases/download/v${GO_BINDATA_VERSION}/go-bindata-linux-amd64 \
    && [ $(sha256sum go-bindata-linux-amd64 | cut -f1 -d' ') = ${GO_BINDATA_SHA256SUM} ] \
    && chmod 755 go-bindata-linux-amd64 \
    && mv go-bindata-linux-amd64 /usr/local/bin/go-bindata

#install goreleaser
ARG GORELEASER_VERSION=0.142.0
ARG GORELEASER_SHA256SUM=eb61a73f5b0947abb8d85074b7bcfd06460f869f3c5708c73800bd57668e55a2
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/goreleaser_Linux_x86_64.tar.gz \
    && [ $(sha256sum goreleaser_Linux_x86_64.tar.gz | cut -f1 -d' ') = ${GORELEASER_SHA256SUM} ] \
    && mkdir -p goreleaser_Linux_x86_64 \
    && tar xf goreleaser_Linux_x86_64.tar.gz -C goreleaser_Linux_x86_64 \
    && mv goreleaser_Linux_x86_64/goreleaser /usr/local/bin \
    && rm -rf goreleaser_Linux_x86_64

# install shellcheck
ARG SHELLCHECK_VERSION=0.7.1
ARG SHELLCHECK_SHA256SUM=64f17152d96d7ec261ad3086ed42d18232fcb65148b44571b564d688269d36c8
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz \
    && [ $(sha256sum shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz | cut -f1 -d' ') = ${SHELLCHECK_SHA256SUM} ] \
    && tar xvfa shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz \
    && mv shellcheck-v${SHELLCHECK_VERSION}/shellcheck /usr/local/bin \
    && chown root:root /usr/local/bin/shellcheck \
    && rm -vrf shellcheck-v${SHELLCHECK_VERSION} shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz

# install terraform
ARG TERRAFORM_VERSION=0.13.0
ARG TERRAFORM_SHA256SUM=9ed437560faf084c18716e289ea712c784a514bdd7f2796549c735d439dbe378
RUN set -ex && cd ~ \
    && curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && [ $(sha256sum terraform_${TERRAFORM_VERSION}_linux_amd64.zip | cut -f1 -d ' ') = ${TERRAFORM_SHA256SUM} ] \
    && unzip -o -d /usr/local/bin -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && rm -vf terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# install terraform-docs
ARG TERRAFORM_DOCS_VERSION=0.9.1
ARG TERRAFORM_DOCS_SHA256SUM=ceb4e7f291d43a5f7672f7ca9543075554bacd02cf850e6402e74f18fbf28f7e
RUN set -ex && cd ~ \
    && curl -sSLO https://github.com/segmentio/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64 \
    && [ $(sha256sum terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64 | cut -f1 -d' ') = ${TERRAFORM_DOCS_SHA256SUM} ] \
    && chmod 755 terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64 \
    && mv terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64 /usr/local/bin/terraform-docs

# install awscliv2, disable default pager (less)
ENV AWS_PAGER=""
ARG AWSCLI_VERSION=2.0.42
COPY sigs/awscliv2_pgp.key /tmp/awscliv2_pgp.key
RUN gpg --import /tmp/awscliv2_pgp.key
RUN set -ex && cd ~ \
    && curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o awscliv2.zip \
    && curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip.sig" -o awscliv2.sig \
    && gpg --verify awscliv2.sig awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install --update \
    && aws --version \
    && rm -r awscliv2.zip awscliv2.sig aws

USER circleci