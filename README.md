# docker-circleci

[![Build status](https://img.shields.io/circleci/project/github/trussworks/docker-circleci/master.svg?style=svg)](https://circleci.com/gh/trussworks/docker-circleci/tree/master)

This is [Truss](https://truss.works/)' custom-built docker image for use with CircleCI 2.x jobs. It is built off of CircleCI's Python 3.8.x convenience image with the following tools installed:

- [pre-commit](http://pre-commit.com/)
- [ShellCheck](https://www.shellcheck.net/)
- [Terraform](https://www.terraform.io/) 0.13.x
- [terraform-docs](https://github.com/segmentio/terraform-docs)
- [go 1.15.x](https://golang.org/)
- [goreleaser](https://goreleaser.com/go)
- [go-bindata](https://github.com/kevinburke/go-bindata)
- [AWS CLI](https://aws.amazon.com/cli/)

Additionally, this image can also be used to perform Python-related tasks as the base image comes with the following Python tools:

- [pip](https://pip.pypa.io/en/stable/)
- [pipenv](https://pipenv-fork.readthedocs.io/en/latest/)
- [poetry](https://python-poetry.org/)
