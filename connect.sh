#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev"

docker exec -it \
  "${DOCKER_IMAGE_NAME}" \
  bash -l
