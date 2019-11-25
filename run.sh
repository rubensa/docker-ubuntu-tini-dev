#!/usr/bin/env bash

# Get current user UID
USER_ID=$(id -u)
# Get current user main GID
GROUP_ID=$(id -g)

prepare_docker_timezone() {
  # https://www.waysquare.com/how-to-change-docker-timezone/
  ENV_VARS+=" --env=TZ=$(cat /etc/timezone)"
}

prepare_docker_user_and_group() {
  RUNNER+=" --user=${USER_ID}:${GROUP_ID}"
}

prepare_docker_timezone
prepare_docker_user_and_group

docker run --rm -it \
  --name "ubuntu-tini-dev" \
  ${ENV_VARS} \
  ${RUNNER} \
  rubensa/ubuntu-tini-dev "$@"