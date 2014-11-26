#!/bin/bash

# Recompile Mellanox OFED drivers for the current kernel on Ubuntu

readonly tag=`basename $0`
readonly package=mlnx-ofed-kernel
readonly ubuntu_file="/etc/os-release"

function log() {
   priority=$1
   msg=$2
   echo -e "${tag}\t${priority}: ${msg}"
}

function ensure_distro() {
    if [ ! -f ${ubuntu_file} ]; then
        msg="skipping Mellanox OFED drivers recompilation,"
        msg="${msg} it is required only on Ubuntu distribution"
        log warning $msg
        exit 1
    fi
}

function recompile_module() {
    ensure_distro

    log info "querying current version of ${package}"
    version=`dpkg-query -W -f='${Version}' "$package-dkms" | sed -e 's/[+-].*//'`

    # remove the current module if exists
    module_status=`dkms status -m "$name" -v "$version"`
    if [[ -n $module_status ]] ; then
        log info "removing ${package} ${version} module"
        dkms remove -m mlnx-ofed-kernel -v "$version" --all > /dev/null
    fi

    # add the module
    log info "adding the module ${package} ${version}"
    dkms add -m "$package" -v "$version" > /dev/null

    # build and install the modules on the current kernel
    log info "building and installing the module"
    dkms build -m "$package" -v "$version" > /dev/null &&
    dkms install -m "$package" -v "$version" --force > /dev/null || true
}

function get_status() {
    if [[ `dkms status -m mlnx-ofed-kernel` =~ 'Diff between built and installed module' ]]; then
        echo 'ERROR' && exit 1
    else
        echo 'OK' && exit 0
    fi
}

function restart_ofed() {
    service openibd restart
}


case $1 in
    status)
        get_status
        ;;
    recompile)
        recompile_module
        restart_ofed
        ;;
    *) echo "Usage: ${tag} {status|recompile}"
       exit 1
esac
