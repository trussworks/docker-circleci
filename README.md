# circleci-pre-commit

[![Build status](https://img.shields.io/circleci/project/github/trussworks/circleci-pre-commit/master.svg)](https://circleci.com/gh/trussworks/circleci-pre-commit/tree/master)

This is [Truss](https://truss.works/)' custom-built docker image for use with CircleCI 2.x jobs to run pre-commit and validate commits. It is built off of CircleCI's Python 3.8.x convenience image with the following tools installed:

- [pre-commit](http://pre-commit.com/)
- [ShellCheck](https://www.shellcheck.net/)
