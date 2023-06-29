#!/bin/sh
SOURCE_SOCKET="/var/run/docker-host.sock"
TARGET_SOCKET="/var/run/docker.sock"
SOCAT_PATH_BASE=/tmp/docker-from-docker
SOCAT_LOG=${SOCAT_PATH_BASE}.log
SOCAT_PID=${SOCAT_PATH_BASE}.pid

# stops the execution of a script if a command or pipeline has an error
set -e
# Wrapper function to only use sudo if not already root
sudoIf()
{
  if [ "$(id -u)" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}
# Log messages
log()
{
  echo -e "[$(date)] $@" | sudoIf tee -a ${SOCAT_LOG} > /dev/null
}
echo -e "n** $(date) **" | sudoIf tee -a ${SOCAT_LOG} > /dev/null
log "Ensuring ${USER_NAME} has access to ${SOURCE_SOCKET} via ${TARGET_SOCKET}"
# use socat to forward the docker socket to another unix socket so 
# that we can set permissions on it without affecting the host.
SOCKET_GID=$(stat -c '%g' ${SOURCE_SOCKET})
# Enable proxy if not already running
if [ ! -f "${SOCAT_PID}" ] || ! ps -p $(cat ${SOCAT_PID}) > /dev/null; then
  log "Enabling socket proxy."
  log "Proxying ${SOURCE_SOCKET} to ${TARGET_SOCKET} for docker from docker usage"
  sudoIf rm -rf ${TARGET_SOCKET}
  (sudoIf socat -t100 UNIX-LISTEN:${TARGET_SOCKET},fork,mode=660,user=${USER_NAME} UNIX-CONNECT:${SOURCE_SOCKET} 2>&1 | sudoIf tee -a ${SOCAT_LOG} > /dev/null & echo "$!" | sudoIf tee ${SOCAT_PID} > /dev/null)
else
  log "Socket proxy already running."
fi
log "Success"

# Execute whatever commands were passed in (if any). This allows us 
# to set this script to ENTRYPOINT while still executing the default CMD.
set +e
exec "$@"
