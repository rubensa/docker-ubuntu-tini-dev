# Docker image with development tools

This is a Docker image based on [rubensa/ubuntu-tini-user](https://github.com/rubensa/docker-ubuntu-tini-user) and includes various development tools.

## Building

You can build the image like this:

```
#!/usr/bin/env bash

docker build --no-cache \
  -t "rubensa/ubuntu-tini-dev" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .
```

## Running

You can run the container like this (change --rm with -d if you don't want the container to be removed on stop):

```
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

prepare_docker_from_docker() {
    MOUNTS+=" --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker-host.sock"
}

prepare_docker_timezone
prepare_docker_user_and_group
prepare_docker_from_docker

docker run --rm -it \
  --name "ubuntu-tini-dev" \
  ${ENV_VARS} \
  ${MOUNTS} \
  ${RUNNER} \
  rubensa/ubuntu-tini-dev "$@"
```

*NOTE*: Mounting /var/run/docker.sock allows host docker usage inside the container (docker-from-docker).

This way, the internal user UID an group GID are changed to the current host user:group launching the container and the existing files under his internal HOME directory that where owned by user and group are also updated to belong to the new UID:GID.

## Connect

You can connect to the running container like this:

```
#!/usr/bin/env bash

docker exec -it \
  ubuntu-tini-dev \
  bash -l
```

This creates a bash shell run by the internal user.

Once connected...

You can check installed develpment software:

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

docker stop \
  ubuntu-tini-dev
```

## Start

If you run the container without --rm you can start it again like this:

```
#!/usr/bin/env bash

docker start \
  ubuntu-tini-dev
```

## Remove

If you run the container without --rm you can remove once stopped like this:

```
#!/usr/bin/env bash

docker rm \
  ubuntu-tini-dev
```
