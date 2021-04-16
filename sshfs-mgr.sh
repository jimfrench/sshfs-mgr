#!/bin/bash

  echo
  echo "======================================================"
  echo "sshfs-mgr: Manage remote file system mounts with sshfs"
  echo "Written by Jim French, Top Hat Electronics"
  echo "Version 0.2"
  echo "======================================================"
  echo

  if [ "$1" == "-c" ]; then  
    if [ -f "$2" ]; then
      CONFIG_FILE=$2
      echo "Using configuration file: ${CONFIG_FILE}"  

    else
      echo "Specified configuration file doesn't exist, exiting..."
      exit 1
    fi

  else
    CONFIG_FILE="sshfs-mgr.conf"
    echo "Using default configuration file: ${CONFIG_FILE}"
    echo
    echo "If you want to use a different configuration file, run this script with -c option and the filename e.g."
    echo "./sshfs-mgr.sh -c sshfs-mgr-custom.conf"
  fi

  echo

  . $CONFIG_FILE
  [ -n "$USER_LOCAL" ] && echo "Local user:         ${USER_LOCAL}" || NO_CONFIG+="USER_LOCAL, "
  [ -n "$GROUP_LOCAL" ] && echo "Local group:        ${GROUP_LOCAL}" || NO_CONFIG+="GROUP_LOCAL, "
  [ -f "$IDFILE_LOCAL" ] && echo "SSH ID file:        ${IDFILE_LOCAL}" || NO_CONFIG+="IDFILE_LOCAL, "
  [ -n "$DIR_LOCAL" ] && echo "Local mount point:  ${DIR_LOCAL}" || NO_CONFIG+="DIR_LOCAL, "
  [ -n "$PERMISSIONS_LOCAL" ] && echo "Local permissions:  ${PERMISSIONS_LOCAL}" || NO_CONFIG="PERMISSIONS_LOCAL, "
  [ -n "$USER_REMOTE" ] && echo "Remote user:        ${USER_REMOTE}" || NO_CONFIG+="USER_REMOTE, "
  [ -n "$HOST_REMOTE" ] && echo "Remote host:        ${HOST_REMOTE}" || NO_CONFIG+="HOST_REMOTE, "
  [ -n "$DIR_REMOTE" ] && echo "Remote directory:   ${DIR_REMOTE}" || NO_CONFIG+="DIR_REMOTE, "
  [ -n "$OPTIONS" ] && echo "Options:            ${OPTIONS}" || NO_CONFIG+="OPTIONS, "

  echo

  if [ -n "$NO_CONFIG" ]; then
    echo "Exiting on error due to missing or problematic configuration entries: ${NO_CONFIG}"
    exit 1
  fi

  if mount | grep "on ${DIR_LOCAL} type" > /dev/null; then
    echo "The specified remote file system is already mounted, will try to go there and exit..."
    echo
    cd $DIR_LOCAL
    ls -lash
    exit 0

  else
    echo "The specified remote file system is not yet mounted."  
    if [ -d "$DIR_LOCAL" ]; then
      ls -ldh "$DIR_LOCAL"; echo

      echo "However, the specified mount point already exists as above at ${DIR_LOCAL}"
      if [ "$(ls -A $DIR_LOCAL)" ]; then
        echo "and the directory is not empty so going to exit instead of trying to mount anything there."; echo
        echo "Check your configuration and specify a different mount point which is available to be used or created..."; echo
        exit 1

      else
        echo "and the directory is empty so will apply any new configuration changes and try to reuse it as a local mount point..."
      fi

    else    
      echo "The specified mount point does not yet exist, trying to mkdir ${DIR_LOCAL}"
      if mkdir -p "${DIR_LOCAL}"; then
        ls -ldh "$DIR_LOCAL"; echo
        echo "Mount point created successfully as above."

      else
        echo "Failed to mkdir, exiting with error $errno"
        exit $errno
      fi
    fi

    echo
    echo "Applying configuration changes: trying to chown ${USER_LOCAL}:${GROUP_LOCAL} ${DIR_LOCAL}"
    if chown ${USER_LOCAL}:${GROUP_LOCAL} ${DIR_LOCAL}; then
      ls -ldh "$DIR_LOCAL"; echo

      echo "Local owner and group changed successfully if necessary as above, now trying to chmod ${PERMISSIONS_LOCAL} ${DIR_LOCAL}"
      if chmod ${PERMISSIONS_LOCAL} ${DIR_LOCAL}; then
        ls -ldh "$DIR_LOCAL"; echo
        echo "Permissions changed successfully if necessary as above, mount point is ready for use."

      else
        echo "Failed to chmod, exiting with error $errno"
        exit $errno
      fi

    else
      echo "Failed to chown, exiting with error $errno"
      exit $errno
    fi

    ls -ldh "$DIR_LOCAL"
    echo

    PARAMS="${USER_REMOTE}@${HOST_REMOTE}:${DIR_REMOTE} ${DIR_LOCAL} -o IdentityFile=${IDFILE_LOCAL},${OPTIONS}"

    echo "Configuration changes applied successfully as above, now trying to mount filesystem using command line:"
    echo "sshfs ${PARAMS}"
    echo
    echo "Please wait, if there is a problem connecting this will return an error or timeout in about 2 minutes..."

    SECONDS=0
    sshfs $PARAMS
    TIMEOUT=$SECONDS

    if mount | grep "on ${DIR_LOCAL} type" > /dev/null; then
      echo "The specified file system was mounted successfully in ${TIMEOUT} seconds on $(date +%s), will try to go there and exit..."
      echo
      cd $DIR_LOCAL
      ls -lash
      exit 0

    else
      echo "There was an error connecting as above or a timeout of ${TIMEOUT} seconds, exiting on error, check your configuration..."
      exit 1
    fi
  fi
