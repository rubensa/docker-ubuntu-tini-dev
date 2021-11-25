# Docker image with development tools

This is a Docker image based on [rubensa/ubuntu-tini-user](https://github.com/rubensa/docker-ubuntu-tini-user) 18.04 and includes various development tools.  This image includes [old openssl](https://www.openssl.org/source/old/) version builds from [rubensa/ubuntu-openssl-old](https://github.com/rubensa/docker-ubuntu-openssl-old) 18.04 to allow old Ruby versions to be installed.

## Building

You can build the image like this:

```
#!/usr/bin/env bash

DOCKER_REPOSITORY_NAME="rubensa"
DOCKER_IMAGE_NAME="ubuntu-tini-dev"
DOCKER_IMAGE_TAG="18.04"

docker buildx build --platform=linux/amd64,linux/arm64 --no-cache \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .

docker buildx build --load \
  -t "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
  .
```

## Running

You can run the container like this (change --rm with -d if you don't want the container to be removed on stop):

```
#!/usr/bin/env bash

DOCKER_REPOSITORY_NAME="rubensa"
DOCKER_IMAGE_NAME="ubuntu-tini-dev"
DOCKER_IMAGE_TAG="18.04"

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

prepare_docker_from_docker() {
    MOUNTS+=" --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker-host.sock"
}

prepare_docker_timezone
prepare_docker_user_and_group
prepare_docker_from_docker

docker run --rm -it \
  --name "${DOCKER_IMAGE_NAME}" \
  ${ENV_VARS} \
  ${MOUNTS} \
  ${RUNNER} \
  "${DOCKER_REPOSITORY_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" "$@"
```

*NOTE*: Mounting /var/run/docker.sock allows host docker usage inside the container (docker-from-docker).

This way, the internal user UID and group GID are changed to the current host user:group launching the container and the existing files under his internal HOME directory that where owned by user and group are also updated to belong to the new UID:GID.

## Connect

You can connect to the running container like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev"

docker exec -it \
  "${DOCKER_IMAGE_NAME}" \
  bash -l
```

This creates a bash shell run by the internal user.

Once connected...

You can check installed development software:

```
gcc --version
g++ --version
make --version
git version
git lfs install --skip-repo
conda info
sdk version
nvm --version
```

## Stop

You can stop the running container like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev"

docker stop  \
  "${DOCKER_IMAGE_NAME}"
```

## Start

If you run the container without --rm you can start it again like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev"

docker start \
  "${DOCKER_IMAGE_NAME}"
```

## Remove

If you run the container without --rm you can remove once stopped like this:

```
#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev"

docker rm \
  "${DOCKER_IMAGE_NAME}"
```
