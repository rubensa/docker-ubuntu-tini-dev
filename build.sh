#!/usr/bin/env bash

docker buildx build --platform=linux/amd64,linux/arm64 --no-cache \
  -t "rubensa/ubuntu-tini-dev" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .

docker buildx build --load \
	-t "rubensa/ubuntu-tini-dev" \
	.