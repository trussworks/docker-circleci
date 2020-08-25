
# CircleCI docker image to run within
FROM cimg/python:3.8.5
# Base image uses "circleci", to avoid using `sudo` run as root user
USER root

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

# install pip packages
ARG CACHE_PIP
ADD ./requirements.txt /tmp/requirements.txt
RUN set -ex && cd ~ \
    && pip install -r /tmp/requirements.txt --no-cache-dir --disable-pip-version-check \
    && rm -vf /tmp/requirements.txt

# install terraform
ARG TERRAFORM_VERSION=0.13.0
ARG TERRAFORM_SHA256SUM=9ed437560faf084c18716e289ea712c784a514bdd7f2796549c735d439dbe37
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

USER circleci