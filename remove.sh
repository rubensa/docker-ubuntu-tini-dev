#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev"

docker rm \
  "${DOCKER_IMAGE_NAME}"
