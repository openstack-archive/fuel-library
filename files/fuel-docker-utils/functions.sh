#!/bin/bash
#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

if ${DEBUG}; then
  DOCKER="docker -D"
else
  DOCKER="docker"
fi

function show_usage {
  echo "Usage:"
  echo "  $0 command"
  echo
  echo "Available commands:"
  echo "  help: show this message"
  echo "  build: create all Docker containers"
  echo "  create: create container without running (or starting) it"
  echo "  list: list container short names (-l for more output)"
  echo "  start: start all Docker containers"
  echo "  restart: restart one or more Docker containers"
  echo "  stop: stop one or more Docker containers"
  echo "  shell: start a shell or run a command in a Docker container"
  echo "  logs: print console log from a container"
  echo "  revert: reset container to original state"
  echo "  destroy: destroy one or more containers"
  echo "  copy: copy files in or out of container"
  echo "  check: check of container is ready"
  echo "  backup: back up entire deployment (--full to include containers, puppet and repos)"
  echo "  restore: restore backed up deployment (--full includes containers)"
  echo "  inspect: display low-level information on a container"
}

function parse_options {
  while [ -n "$1" ]; do
    case "$1" in
      -V|--version) VERSION_OVERRIDE=$2
                    shift 2
                    ;;
      -d|--debug)   DEBUG=true
                    shift
                    ;;
      --nodebug)    DEBUG=false
                    shift
                    ;;
      --)           shift
                    nonopts+=("$@")
                    return
                    ;;
      help|build|create|start|check|list|copy|restart|stop|revert|shell|upgrade|restore|backup|destroy|logs|post_start_hooks)
                    nonopts+=("$@")
                    return
                    ;;
      -*)           echo "Unrecognized option: $opt" 1>&2
                    exit 1
                    ;;
      *)            nonopts+=("$opt")
                    ;;
    esac
  done
}
function debug {
  if $DEBUG; then
    echo $@
  fi
}

function lock {
  [[ $FLOCK -eq 1 ]] && return 0
  exec 904>/var/lock/dockerctl
  flock -n 904 || { echo 'Failed to acquire the lock.' 1>&2; exit 1; }
  FLOCK=1
}

function unlock {
  flock -u 904
  rm -f /var/lock/dockerctl
  FLOCK=0
}

function build_image {
  lock
  ${DOCKER} build -t $2 $1
  unlock
}

function revert_container {
  stop_container $1
  destroy_container $1
  start_container $1
}

function build_storage_containers {
  #Format: build_image $SOURCE_DIR/storage-foo storage/foo
  return 0
}

function retry_checker {
  tries=0
  echo "checking with command \"$*\""
  until eval $*; do
     rc=$?
     let 'tries=tries+1'
     echo "try number $tries"
     echo "return code is $rc"
     if [ $tries -gt $CHECK_RETRIES ];then
        failure=1
     break
  fi
     sleep 5
  done
}

function get_service_credentials {
  credentialfile=$(mktemp /tmp/servicepws.XXXXX)
  get_service_credentials.py $ASTUTE_YAML > $credentialfile
  . $credentialfile
  rm -f $credentialfile
}

function check_ready {
  #Uses a custom command to ensure a container is ready
  get_service_credentials
  failure=0
  echo "checking container $1"

  case $1 in
      nailgun)  if [ "${SYSTEMD:-false}" = "true" ]; then
                  retry_checker "shell_container nailgun systemctl is-active nailgun"
                else
                  retry_checker "shell_container nailgun supervisorctl status nailgun | grep -q RUNNING"
                fi
      ;;
      ostf) retry_checker "egrep -q ^[2-4][0-9]? < <(curl --connect-timeout 1 -s -w '%{http_code}' http://$ADMIN_IP:8777/ostf/not_found -o /dev/null)" ;;
      #NOTICE: Cobbler console tool does not comply unix conversation: 'cobbler profile find' always return 0 as exit code
      cobbler) retry_checker "shell_container cobbler ps waux | grep -q 'cobblerd -F' && pgrep dnsmasq"
               retry_checker "shell_container cobbler cobbler profile find --name=centos* | grep -q centos && shell_container cobbler cobbler profile find --name=ubuntu* | grep -q ubuntu && shell_container cobbler cobbler profile find --name=bootstrap* | grep -q bootstrap" ;;
      rabbitmq) retry_checker "curl -f -L -i  -u \"$astute_user:$astute_password\" http://$ADMIN_IP:15672/api/nodes  1>/dev/null 2>&1"
                retry_checker "curl -f -L -u \"$mcollective_user:$mcollective_password\" -s http://$ADMIN_IP:15672/api/exchanges | grep -qw 'mcollective_broadcast'"
                retry_checker "curl -f -L -u \"$mcollective_user:$mcollective_password\" -s http://$ADMIN_IP:15672/api/exchanges | grep -qw 'mcollective_directed'" ;;
      postgres) retry_checker "shell_container postgres PGPASSWORD=$postgres_nailgun_password /usr/bin/psql -h $ADMIN_IP -U \"$postgres_nailgun_user\" \"$postgres_nailgun_dbname\" -c '\copyright' 2>&1 1>/dev/null" ;;
      astute) retry_checker "shell_container astute ps waux | grep -q 'astuted'"
              retry_checker "curl -f -L -u \"$astute_user:$astute_password\" -s http://$ADMIN_IP:15672/api/exchanges | grep -qw 'nailgun'"
              retry_checker "curl -f -L -u \"$astute_user:$astute_password\" -s http://$ADMIN_IP:15672/api/exchanges | grep -qw 'naily_service'" ;;
      rsync) retry_checker "shell_container rsync netstat -ntl | grep -q 873" ;;
      rsyslog) retry_checker "shell_container rsyslog netstat -nl | grep -q 514" ;;
      mcollective) retry_checker "shell_container mcollective ps waux | grep -q mcollectived" ;;
      nginx) retry_checker "shell_container nginx ps waux | grep -q nginx"  ;;
      keystone) retry_checker "shell_container keystone keystone  --os-auth-url \"http://$ADMIN_IP:35357/v2.0\" --os-username \"$keystone_nailgun_user\" --os-password \"$keystone_nailgun_password\" token-get &>/dev/null" ;;
      *) echo "No defined test for determining if $1 is ready."
                ;;
  esac

  #Catch all to ensure puppet is not running
  retry_checker "! shell_container $1 pgrep puppet"

  if [ $failure -eq 1 ]; then
    echo "ERROR: $1 failed to start."
    return 1
  else
    echo "$1 is ready."
    return 0
  fi
}


function run_storage_containers {
  #Run storage containers once
  #Note: storage containers exit, but keep volumes available
  #Example:
  #${DOCKER} run -d ${CONTAINER_VOLUMES[$FOO_CNT]} --name "$FOO_CNT" storage/foo || true
  return 0
}

function export_containers {
  lock

  #--trim option removes $CNT_PREFIX from container name when exporting
  if [[ "$1" == "--trim" ]]; then
    trim=true
    shift
  else
    trim=false
  fi

  for image in $@; do
    [ $trim ] && image=$(sed "s/${CNT_PREFIX}//" <<< "$image")
    ${DOCKER} export $1 | gzip -c > "${image}.tar.gz"
  done

  unlock
}

function list_containers {
  #Usage:
  # (no option) short names
  # -l (short and long names and status)
  if [[ "$1" = "-l" ]]; then
    printf "%-13s%-25s%-13s%-25s\n" "Name" "Image" "Status" "Full container name"
    for container in "${!CONTAINER_NAMES[@]}"; do
      if container_created $container; then
        if is_running $container; then
          running="Running"
        else
          running="Stopped"
        fi
      else
        running="Not created"
      fi
      longname="${CONTAINER_NAMES["$container"]}"
      imagename="${IMAGE_PREFIX}/${container}_${VERSION}"
      printf "%-13s%-25s%-13s%-25s\n" "$container" "$imagename" "$running" "$longname"
    done
  else
    for container in "${!CONTAINER_NAMES[@]}"; do
      echo $container
    done
  fi
}

function commit_container {
  container_name="${CONTAINER_NAMES[$1]}"
  image="$IMAGE_PREFIX/$1_$VERSION"
  ${DOCKER} commit $container_name $image
}

function create_container() {
  # wrapper for systemd unit
  if [ -z "$1" ]; then
    echo "Must specify a container name" 1>&2
    exit 1
  fi
  if [ "$1" = "all" ]; then
    for container in $CONTAINER_SEQUENCE; do
      create_container $container
    done
    return
  fi
  opts="${CONTAINER_OPTIONS[$1]} ${CONTAINER_VOLUMES[$1]}"
  container_name="${CONTAINER_NAMES[$1]}"
  image="$IMAGE_PREFIX/$1_$VERSION"
  if ! container_created $container_name; then
    pre_setup_hooks $1
    ${DOCKER} create $opts --privileged --name=$container_name $image
    post_setup_hooks $1
  fi
  return 0
}

function start_container {
  lock
  if [ -z "$1" ]; then
    echo "Must specify a container name" 1>&2
    exit 1
  fi
  if [ "$1" = "all" ]; then
    for container in $CONTAINER_SEQUENCE; do
      start_container $container
    done
    return
  fi
  image_name="$IMAGE_PREFIX/$1"
  container_name=${CONTAINER_NAMES[$1]}
  if container_created "$container_name"; then
    pre_start_hooks $1
    if is_running "$container_name"; then
      if is_ghost "$container_name"; then
        restart_container $1
      else
        echo "$container_name is already running."
      fi
    else
      # Clean up broken mounts if needed
      id=$(get_container_id $container_name)
      grep "$id" /proc/mounts | awk '{print $2}' | sort -r | xargs --no-run-if-empty -n1 umount -l 2>/dev/null
      if [ -x "$SYSTEMCTL" ] ; then
        ${SYSTEMCTL} start "docker-${container}"
      else
        ${DOCKER} start $container_name
      fi
    fi
    post_start_hooks $1
    if [ -z "$SUPERVISOR_PROCESS_NAME" -a -n "$(get_supervisor_pid)" ]; then
      #Refresh supervisor for container in case it was disabled
      supervisorctl start docker-$container > /dev/null
    fi
    if [ "$2" = "--attach" ]; then
      unlock
      attach_container $container_name
    fi
  else
    first_run_container "$1" $2
  fi
  # Make sure that the systemd manage the service
  if [ -x "$SYSTEMCTL" ] ; then
    if ! ${SYSTEMCTL} is-active "docker-$1" > /dev/null; then
      ${SYSTEMCTL} start "docker-$1"
    fi
  fi
  unlock
}

function get_CONTAINER_NAMES_idx {
  for idx in ${!CONTAINER_NAMES[@]} ; do
    [  "${CONTAINER_NAMES[${idx}]}" == "$1" ] && echo $idx
  done
}


function shutdown_container {
  echo "Stopping $1..."
  kill $2
  if [ -x "$SYSTEMCTL" ] ; then
    ${SYSTEMCTL} stop "docker-$( get_CONTAINER_NAMES_idx $1) "
  else
    ${DOCKER} stop ${1}
  fi
  exit 0
}

function attach_container {
  echo "Attaching to container $1..."
  ${DOCKER} attach --no-stdin $1 &
  APID=$!
  trap "shutdown_container $1 $APID" INT TERM
  while test -d "/proc/$APID/fd" ; do
    sleep 10 & wait $!
  done
}

function shell_container {
  exec_shell_container "$@"
}

function exec_shell_container {
  exec_opts=''
  #Interactive shell only if we have TTY
  if [ -t 0 ]; then
    exec_opts+=' -i'
  else
    #FIXME(mattymo): BASH 3.1.3 and higher don't need sleep
    sleep 0.1
    if read -t 0; then
      exec_opts+=' -i'
    fi
  fi
  if [ -t 1 -a ! -p /proc/self/fd/0 ]; then
    exec_opts+=' -t'
  fi
  id=$(get_container_id "$1")
  if [ $? -ne 0 ]; then
    echo "Could not get docker ID for $container. Is it running?" 1>&2
    return 1
  fi
  #TODO(mattymo): fix UTF-8 bash warning
  #Setting C locale to suppress bash warning
  prefix="env LANG=C"
  if [ -z "$2" ]; then
    command="/bin/bash"
  else
    shift
    command=("$@")
  fi
  docker exec $exec_opts $id $prefix "${command[@]}"
}

function stop_container {
  lock
  if [ "$1" = "all" ]; then
    for container in ${!CONTAINER_NAMES[@]}; do
      stop_container $container
    done
    return
  fi
  for container in $@; do
    echo "Stopping $container..."
    #Stop supervisor process if manually shut down by user
    if [ -z "$SUPERVISOR_PROCESS_NAME" -a -n "$(get_supervisor_pid)" ]; then
      supervisorctl stop "docker-${container}" > /dev/null
    fi
      if [ -x "$SYSTEMCTL" ] ; then
        ${SYSTEMCTL} stop "docker-${container}"
      else
        ${DOCKER} stop ${CONTAINER_NAMES[$container]}
      fi
  done
  unlock
}

function destroy_container {
  lock

  if [[ "$1" == 'all' ]]; then
    stop_container all
    ${DOCKER} rm -f ${CONTAINER_NAMES[@]}
  else
    for container in $@; do
      stop_container $container
      ${DOCKER} rm -f ${CONTAINER_NAMES[$container]}
      if [ $? -ne 0 ]; then
        #This happens because devicemapper glitched
        #Try to unmount all devicemapper mounts manually and try again
        echo "Destruction of container $container failed. Trying workaround..."
        id=$(${DOCKER} inspect -f='{{if .ID}}{{.ID}}{{else}}{{.Id}}{{end}}' ${CONTAINER_NAMES[$container]})
        if [ -z $id ]; then
          echo "Could not get docker ID for $container" 1>&2
          return 1
        fi
        umount -l $(grep "$id" /proc/mounts | awk '{print $2}' | sort -r)
        #Try to delete again
        ${DOCKER} rm -f ${CONTAINER_NAMES[$container]}
        if [ $? -ne 0 ];then
          echo "Workaround failed. Unable to destroy container $container."
        fi
      fi
    done
  fi

  unlock
}

function logs {
  ${DOCKER} logs ${CONTAINER_NAMES[$1]}
}

function inspect {
  local container

  if (( $# == 0 )); then
    docker inspect
    return 0
  fi


  for container in $@; do
    found="$(docker ps -a -q --filter="name=${CONTAINER_NAMES[$container]}" | wc -l)"

    if [[ $? -ne 0 || $found -ne 1 ]]; then
      echo "Could not find the $container container" 1>&2
      continue
    fi

    ${DOCKER} inspect ${CONTAINER_NAMES[$container]}
  done
}

function restart_container {
  if [ -x "$SYSTEMCTL" ] ; then
    ${SYSTEMCTL} restart "docker-${1}"
  else
    ${DOCKER} restart ${CONTAINER_NAMES[$1]}
  fi
}

function container_lookup {
  echo ${CONTAINER_NAMES[$1]}
}

function get_container_id {
  #Try to get ID from container short name first
  id=$(${DOCKER} inspect -f='{{if .ID}}{{.ID}}{{else}}{{.Id}}{{end}}' ${CONTAINER_NAMES[$1]} 2>/dev/null)
  if [ -z "$id" ]; then
     #Try to get ID short ID, long ID, or container name
     id=$(${DOCKER} inspect -f='{{if .ID}}{{.ID}}{{else}}{{.Id}}{{end}}' "$1")
     if [ -z "$id" ]; then
       echo "Could not get docker ID for container $1. Is it running?" 1>&2
       return 1
     fi
  fi
  echo "$id"
}
function container_created {
  ${DOCKER} ps -a | grep -q $1
  return $?
}
function is_ghost {
  LANG=C ${DOCKER} ps | grep $1 | grep -q Ghost
  return $?
}
function is_running {
  ${DOCKER} ps | grep -q $1
  return $?
}
function first_run_container {

  opts="${CONTAINER_OPTIONS[$1]} ${CONTAINER_VOLUMES[$1]}"
  container_name="${CONTAINER_NAMES[$1]}"
  image="$IMAGE_PREFIX/$1_$VERSION"
  if ! is_running $container_name; then
      pre_setup_hooks $1
      ${DOCKER} run $opts $BACKGROUND --privileged --name=$container_name $image
      post_setup_hooks $1
  else
      echo "$container_name is already running."
  fi
  if [ "$2" = "--attach" ]; then
      attach_container $container_name
  fi
  return 0
}

function pre_setup_hooks {
  return 0
}

function pre_start_hooks {
  return 0
}

function post_setup_hooks {
  case $1 in
    *)         ;;
  esac
}
function post_start_hooks {
  case $1 in
    *)         ;;
  esac
}

function container_root {
  id=$(${DOCKER} inspect -f='{{if .ID}}{{.ID}}{{else}}{{.Id}}{{end}}' ${CONTAINER_NAMES[$1]})
  if [ -n "$id" ]; then
    echo "/var/lib/docker/devicemapper/mnt/${id}/rootfs"
    return 0
  else
    echo "Unable to get root for container ${1}." 1>&2
    return 1
  fi
}

function copy_files {
  #Overview:
  # Works similar to rsync:
  # Container to host:
  #   sync_files cobbler:/var/lib/tftpboot/ /localpath/
  # Host to container:
  #   sync_files /etc/puppet cobbler:/etc/puppet
  #TODO(mattymo): add options and more parameters

  if [ -z "$2" ]; then
    echo "This command requires two parameters. See usage:"
    echo "  $0 copy src dest"
    echo
    echo "Examples:"
    echo "  $0 copy nailgun:/etc/nailguns/settings.yaml /root/settings.yaml"
    echo "  $0 copy /root/newpkg.rpm mcollective:/root/"
    exit 1
  fi
  #Test which parameter is local
  if test -n "$(shopt -s nullglob; echo $1*)"; then
    method="push"
    local=$1
    remote=$2
  else
    method="pull"
    remote=$1
    local=$2
  fi
  container=$(echo $remote | cut -d':' -f1)
  remotepath=$(echo $remote | cut -d':' -f2-)
  if [[ ! ${CONTAINER_NAMES[@]} =~ .*${container}.* ]]; then
    echo "Unable to locate container named '${container}' to copy to/from."
    return 2
  fi

  docker_version=$(get_docker_version)
  if versioncmp_gte $docker_version '1.8'; then
    remote="${CONTAINER_NAMES[$container]}:${remotepath}"
    if [[ "$method" = "push" ]]; then
      ${DOCKER} cp $local $remote
    else
      ${DOCKER} cp $remote $local
    fi
  else
    cont_root=$(container_root $container)
    if [ $? -ne 0 ];then return 1; fi
    remote="${cont_root}/${remotepath}"
    if [[ "$method" = "push" ]]; then
      cp -R $local $remote
    else
      cp -R $remote $local
    fi
  fi
}

function backup {
  set -e
  lock
  trap backup_fail EXIT

  local fullbackup
  fullbackup=0
  if [ "$1" = "--full" ]; then
    fullbackup=1
    shift
  elif [ "$2" = "--full" ]; then
    fullbackup=1
  fi

  backup_id=$(date +%F_%H%M)
  image_suffix="_${backup_id}"
  use_rsync=0
  #Sets backup_dir
  parse_backup_dir $1
  [[ $use_rsync -eq 1 ]] && ssh_copy_id
  mkdir -p $SYSTEM_DIRS $backup_dir
  verify_disk_space "backup" "$fullbackup"
  if check_nailgun_tasks; then
    echo "There are currently running Fuel tasks. Please wait for them to \
finish or cancel them." 1>&2
    exit 1
  fi
  if [[ "$fullbackup" == "1" ]]; then
    backup_containers "$backup_id"
    backup_system_dirs --full
  else
    backup_system_dirs
  fi
  backup_postgres_db
  backup_compress
  [ $use_rsync -eq 1 ] && backup_rsync_upload $rsync_dest $backup_dir
  backup_cleanup $backup_dir
  echo "Backup complete. File is available at $backup_dir/fuel_backup${image_suffix}.tar.lrz"
  #remove trap
  trap - EXIT
  unlock
}

function backup_fail {
  exit_code=$?
  echo "Backup failed!" 1>&2
  unlock
  exit $exit_code
}

function ssh_copy_id {
  user_hostname=$(cut -d":" -f1 <<< "$rsync_dest")
  if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
    echo "private key not found"
    echo "create private key with ssh-keygen"
    ssh-keygen -t rsa -b 2048 -N '' -f ~/.ssh/id_rsa
  fi
  ssh-copy-id $user_hostname
  #remove duplicate keys
  ssh $user_hostname "sed -i \"\\\$!{/$(whoami)@$(hostname)/d;}\" ~/.ssh/authorized_keys"
}

function parse_backup_dir {
  use_rsync=0
  if [ -z "$1" ]; then
    #Default backup dir
    backup_dir="${BACKUP_ROOT}/backup_${backup_id}"
  elif [ -d "$1" ]; then
    #User defined dir exists, so use it
    backup_dir="$1"
  elif [[ "$1" =~ .:. ]]; then
    #Remote rsync dir
    use_rsync=1
    backup_dir="${BACKUP_ROOT}/backup_${backup_id}"
    rsync_dest="$1"
  else
    echo "Unrecognized backup destination. Valid options include:" 1>&2
    echo "  (blank)           - backup to $BACKUP_ROOT" 1>&2
    echo "  /path/to/backup   - local backup directory" 1>&2
    echo "  user@server:/path - backup using rsync to server" 1>&2
    exit 1
  fi
}

function backup_system_dirs {
#Pauses containers, backs up system dirs, and then unpauses
#--full option includes $FULL_BACKUP_DIRS

  echo "Pausing containers..."
  ${DOCKER} ps -q | xargs -n1 --no-run-if-empty ${DOCKER} pause

  echo "Archiving system folders"
  tar cf $backup_dir/system-dirs.tar -C / $SYSTEM_DIRS

  if [[ "$1" == "--full" ]]; then
    tar rf $backup_dir/system-dirs.tar -C / $FULL_BACKUP_DIRS
  fi

  echo "Unpausing containers..."
  ${DOCKER} ps -a | grep Paused | cut -d' ' -f1 | xargs -n1 --no-run-if-empty ${DOCKER} unpause
}

function backup_containers {
#Backs up all containers, regardless of being related to Fuel

  purge_images=0

  [ $purge_images -eq 0 ] && rm -rf "$backup_dir"
  mkdir -p $SYSTEM_DIRS $backup_dir
  echo "Reading container data..."
  while read containerid; do
    container_name="$(${DOCKER} inspect -f='{{.Name}}' $containerid | tr -d '/')"
    container_image="$(${DOCKER} inspect -f='{{.Config.Image}}' $containerid)"
    container_image+=$image_suffix
    container_archive="$(echo "$container_image" | sed 's/\//__/').tar"
    #Commit container as new image
    echo "Committing $container_name..."
    ${DOCKER} commit "$containerid" "${container_image}"
  done < <(${DOCKER} ps -aq)
  echo "Saving containers to combined archive..."
  images_to_save=$(${DOCKER} images | grep $image_suffix | cut -d' ' -f1)
  ${DOCKER} save $images_to_save > "${backup_dir}/docker-images.tar"
  echo "Cleaning up temporary images..."
  ${DOCKER} rmi $images_to_save
}
function backup_postgres_db {
  if [ -n "$1" ];then
    dst=$1
  else
    dst="$backup_dir/postgres_backup.sql"
  fi
  echo "Backing up PostgreSQL database to ${dst}..."
  shell_container postgres su - postgres -c 'pg_dumpall --clean' > "$dst"
}

function backup_compress {
  echo "Compressing archives..."
  component_tars=($backup_dir/*.tar)
  ( cd $backup_dir && tar cf $backup_dir/fuel_backup${image_suffix}.tar *.tar *.sql)
  rm -rf "${component_tars[@]}"
  #Improve compression on bare metal
  if [ -z "$(virt-what)" ] ; then
    lrzopts="-L2 -U"
  else
    lrzopts="-L2 -w 5"
  fi
  lrzip $lrzopts "$backup_dir/fuel_backup${image_suffix}.tar" -o "$backup_dir/fuel_backup${image_suffix}.tar.lrz"

}

function backup_rsync_upload {
  dest="$1"
  backup_dir="$2"
  echo "Starting rsync backup. You may be prompted for a login."
  rsync -vP $backup_dir/*.tar.lrz "$dest"
}

function backup_cleanup {
  echo "Cleaning up..."
  [ -d "$1" ] && rm -f $1/*.tar
}

function check_nailgun_tasks {
#Returns 0 if tasks are running in nailgun
  #if command returns error, then app is not running
  shell_container nailgun fuel task &> /dev/null || return 1
  shell_container nailgun fuel task | grep -q running &> /dev/null
  return $?
}

# Defer expression evaluation until the current subshell exits.
# They will be called in reverse order.
# Think of it as of appending an expression to the top of a finally{…}
# block after a try{…}, so it will be evaluated no matter whether an
# error occurs or not. It looks cleaner than multiple nested scopes
# with EXIT traps.
function defer {
  declare -ga traps
  traps[${#traps[*]}]=`trap`
  local trapcmd
  # We need to escape all shell metacharacters,
  trapcmd="$(printf "%q " "$@"); __finally"
  # and then unescape them inside the trap.
  # This trick ensures that variable expansion will be
  # delayed until the "defer" phase.
  trap "eval eval \"$(printf '"%q" ' "$trapcmd")\"" EXIT
}

# Helper function for "defer".
# It unwinds "traps" stack.
function __finally {
  declare -ga traps
  local cmd
  cmd="${traps[${#traps[@]}-1]}"
  unset traps[${#traps[@]}-1]
  # Parse `trap` output.
  eval set -- "${cmd}"
  if [ "$1/$2/$4" = "trap/--/EXIT" ]; then
    # It's an EXIT trap - evaluate the code.
    eval "$3" || true
  else
    # Other trap - just restore it.
    eval "${cmd}"
  fi
}

function update_ssh_keys {
# Copy masternode's public keys inside the active bootstrap image
  local sqfs relative_path SQ_MOUNT_POINT COMP
  ssh-agent sh -c 'ssh-add ; ssh-add -L' > /tmp/authorized_keys
  sqfs=$(realpath /var/www/nailgun/bootstraps/active_bootstrap/root.squashfs)
  test -s "$sqfs" || return 0
  relative_path=$(realpath --relative-to=/var/www/nailgun/bootstraps "$sqfs")

  (
    set -e

    SQ_MOUNT_POINT=$(mktemp -d)
    defer rmdir $SQ_MOUNT_POINT

    mount -o loop,ro $sqfs $SQ_MOUNT_POINT
    defer umount $SQ_MOUNT_POINT

    mount -t tmpfs tmpfs $SQ_MOUNT_POINT/mnt
    defer umount $SQ_MOUNT_POINT/mnt

    mkdir $SQ_MOUNT_POINT/mnt/{bootstraps,src}
    defer rmdir $SQ_MOUNT_POINT/mnt/{bootstraps,src}

    # Let chroot environment reach out to bootstrap images outside.
    mount --bind /var/www/nailgun/bootstraps $SQ_MOUNT_POINT/mnt/bootstraps
    defer umount $SQ_MOUNT_POINT/mnt/bootstraps

    mount --bind $SQ_MOUNT_POINT $SQ_MOUNT_POINT/mnt/src
    defer umount $SQ_MOUNT_POINT/mnt/src

    # We call unsquashfs inside the bootstrap image because there are no
    # squashfs-tools installed on a node itself.
    COMP=$(chroot $SQ_MOUNT_POINT unsquashfs -s "/mnt/bootstraps/$relative_path" | awk '/Compression/ { print $2 }')

    mount --bind /tmp/authorized_keys $SQ_MOUNT_POINT/root/.ssh/authorized_keys
    defer umount $SQ_MOUNT_POINT/root/.ssh/authorized_keys

    chroot $SQ_MOUNT_POINT mksquashfs /mnt/src/ "/mnt/bootstraps/$relative_path~" -comp $COMP -no-progress -noappend

    mv "$sqfs~" "$sqfs"
  )
}

function restore {
#TODO(mattymo): Optionally not include system dirs during restore
#TODO(mattymo): support remote file such as ssh://user@myhost/backup.tar.lrz
#               or http://myhost/backup.tar.lrz

  local fullrestore
  if [ "$2" = "--full" ]; then
    fullrestore=1
  else
    fullrestore=0
  fi

  set -e
  lock
  trap restore_fail EXIT
  if check_nailgun_tasks; then
    echo "There are currently running Fuel tasks. Please wait for them to \
finish or cancel them. Run \"fuel task list\" for more details." 1>&2
    exit 1
  fi
  verify_disk_space "restore" "$fullrestore"
  backupfile=$1
  if [ -z "$backupfile" ]; then
    #TODO(mattymo): Parse BACKUP_DIR for lrz files
    echo "Specify a backup file to restore" 1>&2
    exit 1
  elif ! [ -f "$backupfile" ]; then
    echo "Archive does not exist: $backupfile" 1>&2
    exit 1
  elif ! [[ "$backupfile" =~ lrz$ ]]; then
    echo "Archive does not have lrz extension." 1>&2
    exit 2
  fi
  timestamp=$(echo $backupfile | sed -n 's/.*\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9][0-9][0-9]\).*/\1/p')
  if [ -z "$timestamp" ]; then
    echo "Unable to parse timestamp in archive." 1>&2
    exit 3
  fi
  restoredir="$BACKUP_ROOT/restore-$timestamp/"
  disable_supervisor
  if [ "$fullrestore" = "1" ]; then
    echo "Stopping and destroying existing containers..."
    destroy_container all
  else
    echo "Stopping containers..."
    stop_container all
  fi
  unpack_archive "$backupfile" "$restoredir"
  [ "$fullrestore" = "1" ] && restore_images "$restoredir"
  [ "$fullrestore" = "1" ] && rename_images "$timestamp"
  # We don't need to update ssh keys for a full backup/restore,
  # because it contains both keys and matching bootstrap images.
  [ "$fullrestore" = "0" ] && update_ssh_keys
  restore_systemdirs "$restoredir"
  set +e
  echo "Starting containers..."
  start_container all
  enable_supervisor
  for container in $CONTAINER_SEQUENCE; do
    check_ready $container
  done
  echo "Restore complete."
  #remove trap
  trap - EXIT
  unlock
}

function restore_fail {
  echo "Restore failed!" 1>&2
  unlock
  exit 1
}

function unpack_archive {
#feedback as everything restores
  backupfile="$1"
  restoredir="$2"
  mkdir -p "$restoredir"
  lrzip -d -o "$restoredir/fuel_backup.tar" $backupfile
  tar -xf "$restoredir/fuel_backup.tar" -C "$restoredir" && rm -f "$restoredir/fuel_backup.tar"
}

function restore_images {
  restoredir="$1"
  for imgfile in $restoredir/*.tar; do
    echo "Loading $imgfile..."
    if ! [[ "$imgfile" =~ system-dirs ]] && ! [[ "$imgfile" =~ fuel_backup.tar ]]; then
      ${DOCKER} load -i $imgfile
    fi
    #rm -f $imgfile
  done
}

function rename_images {
  timestamp="$1"
  while read containername; do
    oldname=$containername
    newname=$(echo $containername | sed -n "s/_${timestamp}//p")
    docker tag -f "$oldname" "$newname"
    docker rmi "$oldname"
  done < <(docker images | grep $timestamp | cut -d' ' -f1)
}

function restore_systemdirs {
  restoredir="$1"
  tar xf $restoredir/system-dirs.tar -C /
}

function get_supervisor_pid {
  # use the supervisorctl pid command to see if supervisord is currently
  # running and return the pid
  SUPERVISOR_PID=`supervisorctl pid | tr -dc '0-9'`
  echo "${SUPERVISOR_PID}"
}

function disable_supervisor {
  SUPERVISOR_PID=$(get_supervisor_pid)
  if [ -z "${SUPERVISOR_PID}" ]; then
    # not running, so return
    return
  fi

  supervisorctl shutdown

  # Supervisord recommends waiting about 60 seconds as the children processes
  # may take a while to stop. So we check every 3 seconds to see if the pid is
  # gone before we continue.
  for I in {1..20}; do
    if [ -d "/proc/${SUPERVISOR_PID}/fd" ]; then
      sleep 3
    else
      break
    fi
  done
}

function enable_supervisor {
  service supervisord start
}

function verify_disk_space {
  if [ -z "$1" ]; then
    echo "Backup or restore operation not specified." 1>&2
    exit 1
  fi
  fullbackup=1
  if [[ "$2" != "$fullbackup" ]]; then
    #2gb free space required for light backup
    (( required  = 2 * 1024 * 1024 ))
    spaceerror="Insufficient disk space to perform $1. At least 2gb must be free on ${BACKUP_ROOT} partition."
  else
     #11gb free space required to backup and restore
     (( required = 11 * 1024 * 1024 ))
    spaceerror="Insufficient disk space to perform $1. At least 11gb must be free on ${BACKUP_ROOT} partition."
  fi
  avail=$(df --output=avail ${BACKUP_ROOT} | tail -1)
  if (( avail < required )); then
    echo "$spaceerror" 1>&2
    exit 1
  fi
}

# This function returns the version of docker using the docker -v command.
# docker -v returns 'Docker version <version>, build <hash>/<version>' so we
# pull the version off the end with awk
function get_docker_version {
  echo $(${DOCKER} -v | awk '{ print $3 }' | sed -e 's/,//g')
}

# This function is used to check that a version is greater than or equal to a
# specific version.
# Usage:
#   versioncmp_gte <version> <version to compare to>
# Example
#   versioncmp_gte 2.3.1 2.2.2 -> returns 0
#   versioncmp_gte 2.1.1 2.2.2 -> returns 1
function versioncmp_gte {
  [ "$1" = "$(echo -e "$1\n$2" | sort -V -r | head -n1)" ]
}
