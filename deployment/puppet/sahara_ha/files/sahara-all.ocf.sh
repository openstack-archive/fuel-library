#!/bin/sh
#
#
# OpenStack Sahara (Data Processing) Service (sahara-all)
#
# Description: Manages an OpenStack Sahara (Data Processing) Service (sahara-all) process as an HA resource.
#
# Authors: Egorenko Denis
# Mainly inspired by the Ceilometer Central Agent written by Emilien Macchi
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0
#
#
# See usage() function below for more details ...
#
# OCF instance parameters:
# OCF_RESKEY_binary
# OCF_RESKEY_config
# OCF_RESKEY_user
# OCF_RESKEY_pid
# OCF_RESKEY_monitor_binary
# OCF_RESKEY_amqp_server_port
# OCF_RESKEY_additional_parameters
#######################################################################
# Initialization:

: ${OCF_FUNCTIONS_DIR=${OCF_ROOT}/lib/heartbeat}
. ${OCF_FUNCTIONS_DIR}/ocf-shellfuncs

#######################################################################

# Fill in some defaults if no values are specified

OCF_RESKEY_binary_default="sahara-all"
OCF_RESKEY_config_default="/etc/sahara/sahara.conf"
OCF_RESKEY_user_default="sahara"
OCF_RESKEY_pid_default="${HA_RSCTMP}/${__SCRIPT_NAME}/${__SCRIPT_NAME}.pid"

: ${OCF_RESKEY_binary=${OCF_RESKEY_binary_default}}
: ${OCF_RESKEY_config=${OCF_RESKEY_config_default}}
: ${OCF_RESKEY_user=${OCF_RESKEY_user_default}}
: ${OCF_RESKEY_pid=${OCF_RESKEY_pid_default}}

#######################################################################

usage() {
    cat <<UEND
        usage: $0 (start|stop|validate-all|meta-data|status|monitor)

        $0 manages an OpenStack Sahara (Data Processing) Service (sahara-all) process as an HA resource.

        The 'start' operation starts the scheduler service.
        The 'stop' operation stops the scheduler service.
        The 'validate-all' operation reports whether the parameters are valid
        The 'meta-data' operation reports this RA's meta-data information
        The 'status' operation reports whether the scheduler service is running
        The 'monitor' operation reports whether the scheduler service seems to be working

UEND
}

meta_data() {
    cat <<END
<?xml version="1.0"?>
<!DOCTYPE resource-agent SYSTEM "ra-api-1.dtd">
<resource-agent name="sahara-all">
<version>1.0</version>

<longdesc lang="en">
Resource agent for OpenStack Sahara (Data Processing) Service (sahara-all)
Sahara project aims to provide users with simple means to provision a Hadoop cluster at
OpenStack by specifying several parameters like Hadoop version, cluster topology,
nodes hardware details and a few more.
</longdesc>
<shortdesc lang="en">Manages the OpenStack OpenStack Sahara (Data Processing) Service (sahara-all)</shortdesc>
<parameters>

<parameter name="binary" unique="0" required="0">
<longdesc lang="en">
Location of the OpenStack Sahara (Data Processing) Service binary (sahara-all)
</longdesc>
<shortdesc lang="en">OpenStack Sahara (Data Processing) Service binary (sahara-all)</shortdesc>
<content type="string" default="${OCF_RESKEY_binary_default}" />
</parameter>

<parameter name="config" unique="0" required="0">
<longdesc lang="en">
Location of the OpenStack Sahara (Data Processing) Service (sahara-all) configuration file
</longdesc>
<shortdesc lang="en">OpenStack Sahara (Data Processing) Service (sahara-all) config file</shortdesc>
<content type="string" default="${OCF_RESKEY_config_default}" />
</parameter>

<parameter name="user" unique="0" required="0">
<longdesc lang="en">
User running OpenStack Sahara (Data Processing) Service (sahara-all)
</longdesc>
<shortdesc lang="en">OpenStack Sahara (Data Processing) Service (sahara-all) user</shortdesc>
<content type="string" default="${OCF_RESKEY_user_default}" />
</parameter>

<parameter name="pid" unique="0" required="0">
<longdesc lang="en">
The pid file to use for this OpenStack Sahara (Data Processing) Service (sahara-all) instance
</longdesc>
<shortdesc lang="en">OpenStack Sahara (Data Processing) Service (sahara-all) pid file</shortdesc>
<content type="string" default="${OCF_RESKEY_pid_default}" />
</parameter>

</parameters>

<actions>
<action name="start" timeout="20" />
<action name="stop" timeout="20" />
<action name="status" timeout="20" />
<action name="monitor" timeout="30" interval="20" />
<action name="validate-all" timeout="5" />
<action name="meta-data" timeout="5" />
</actions>
</resource-agent>
END
}

#######################################################################
# Functions invoked by resource manager actions

sahara_all_validate() {
    local rc

    check_binary $OCF_RESKEY_binary
    check_binary netstat

    # A config file on shared storage that is not available
    # during probes is OK.
    if [ ! -f $OCF_RESKEY_config ]; then
        if ! ocf_is_probe; then
            ocf_log err "Config $OCF_RESKEY_config doesn't exist"
            return $OCF_ERR_INSTALLED
        fi
        ocf_log_warn "Config $OCF_RESKEY_config not available during a probe"
    fi

    getent passwd $OCF_RESKEY_user >/dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
        ocf_log err "User $OCF_RESKEY_user doesn't exist"
        return $OCF_ERR_INSTALLED
    fi

    true
}

sahara_all_status() {
    local pid
    local rc

    # check and make PID file dir
    local PID_DIR="$( dirname ${OCF_RESKEY_pid} )"
    if [ ! -d "${PID_DIR}" ] ; then
        ocf_log debug "Create pid file dir: ${PID_DIR} and chown to ${OCF_RESKEY_user}"
        mkdir -p "${PID_DIR}"
        chown -R ${OCF_RESKEY_user} "${PID_DIR}"
        chmod 755 "${PID_DIR}"
    fi

    if [ ! -f $OCF_RESKEY_pid ]; then
        ocf_log info "OpenStack Sahara (Data Processing) Service (sahara-all) is not running"
        return $OCF_NOT_RUNNING
    else
        pid=`cat $OCF_RESKEY_pid`
    fi

    if [ -n "${pid}" ]; then
      ocf_run -warn kill -s 0 $pid
      rc=$?
    else
      ocf_log err "PID file ${OCF_RESKEY_pid} is empty!"
      return $OCF_ERR_GENERIC
    fi

    if [ $rc -eq 0 ]; then
        return $OCF_SUCCESS
    else
        ocf_log info "Old PID file found, but OpenStack Sahara (Data Processing) Service (sahara-all) is not running"
        return $OCF_NOT_RUNNING
    fi
}

sahara_all_monitor() {
    local rc
    local pid
    local scheduler_amqp_check

    sahara_all_status
    rc=$?

    # If status returned anything but success, return that immediately
    if [ $rc -ne $OCF_SUCCESS ]; then
        return $rc
    fi

    ocf_log debug "OpenStack Sahara (Data Processing) Service (sahara-all) monitor succeeded"
    return $OCF_SUCCESS
}

sahara_all_start() {
    local rc

    sahara_all_status
    rc=$?
    if [ $rc -eq $OCF_SUCCESS ]; then
        ocf_log info "OpenStack Sahara (Data Processing) Service (sahara-all) already running"
        return $OCF_SUCCESS
    fi

    # run sahara-all as daemon. Don't use ocf_run as we're sending the tool's output
    # straight to /dev/null anyway and using ocf_run would break stdout-redirection here.
    su ${OCF_RESKEY_user} -s /bin/sh -c "${OCF_RESKEY_binary} --config-file=$OCF_RESKEY_config \
       $OCF_RESKEY_additional_parameters"' >> /dev/null 2>&1 & echo $!' > $OCF_RESKEY_pid

    ocf_log debug "Create pid file: ${OCF_RESKEY_pid} with content $(cat ${OCF_RESKEY_pid})"
    # Spin waiting for the server to come up.
    while true; do
       sahara_all_monitor
       rc=$?
       [ $rc -eq $OCF_SUCCESS ] && break
       if [ $rc -ne $OCF_NOT_RUNNING ]; then
          ocf_log err "OpenStack Sahara (Data Processing) Service (sahara-all) start failed"
          exit $OCF_ERR_GENERIC
       fi
       sleep 1
    done

    ocf_log info "OpenStack Sahara (Data Processing) Service (sahara-all) started"
    return $OCF_SUCCESS
}

sahara_all_stop() {
    local rc
    local pid

    sahara_all_status
    rc=$?
    if [ $rc -eq $OCF_NOT_RUNNING ]; then
        ocf_log info "OpenStack Sahara (Data Processing) Service (sahara-all) already stopped"
        return $OCF_SUCCESS
    fi

    # Try SIGTERM
    pid=`cat $OCF_RESKEY_pid`
    ocf_run kill -s TERM $pid
    rc=$?
    if [ $rc -ne 0 ]; then
        ocf_log err "OpenStack Sahara (Data Processing) Service (sahara-all) couldn't be stopped"
        exit $OCF_ERR_GENERIC
    fi

    # stop waiting
    shutdown_timeout=15
    if [ -n "$OCF_RESKEY_CRM_meta_timeout" ]; then
        shutdown_timeout=$((($OCF_RESKEY_CRM_meta_timeout/1000)-5))
    fi
    count=0
    while [ $count -lt $shutdown_timeout ]; do
        sahara_all_status
        rc=$?
        if [ $rc -eq $OCF_NOT_RUNNING ]; then
            break
        fi
        count=`expr $count + 1`
        sleep 1
        ocf_log debug "OpenStack Sahara (Data Processing) Service (sahara-all) still hasn't stopped yet. Waiting ..."
    done

    sahara_all_status
    rc=$?
    if [ $rc -ne $OCF_NOT_RUNNING ]; then
        # SIGTERM didn't help either, try SIGKILL
        ocf_log info "OpenStack Sahara (Data Processing) Service (sahara-all) failed to stop after ${shutdown_timeout}s \
          using SIGTERM. Trying SIGKILL ..."
        ocf_run kill -s KILL $pid
    fi

    ocf_log info "OpenStack Sahara (Data Processing) Service (sahara-all) stopped"

    ocf_log debug "Delete pid file: ${OCF_RESKEY_pid} with content $(cat $OCF_RESKEY_pid)"
    rm -f $OCF_RESKEY_pid

    return $OCF_SUCCESS
}

#######################################################################

case "$1" in
  meta-data) meta_data
                exit $OCF_SUCCESS;;
  usage|help) usage
                exit $OCF_SUCCESS;;
esac

# Anything except meta-data and help must pass validation
sahara_all_validate || exit $?

# What kind of method was invoked?
case "$1" in
  start) sahara_all_start;;
  stop) sahara_all_stop;;
  status) sahara_all_status;;
  monitor) sahara_all_monitor;;
  validate-all) ;;
  *) usage
                exit $OCF_ERR_UNIMPLEMENTED;;
esac
