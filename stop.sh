#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev"

docker stop  \
  "${DOCKER_IMAGE_NAME}"
