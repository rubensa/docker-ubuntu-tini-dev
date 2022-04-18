#!/usr/bin/env bash

DOCKER_BUILDKIT=1 docker build --no-cache \
  -t "rubensa/ubuntu-tini-dev" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .
