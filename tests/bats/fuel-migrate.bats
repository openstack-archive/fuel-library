#!/usr/bin/env bats
# For testing use  bats framework -
# https://github.com/sstephenson/bats


fms="$BATS_TEST_DIRNAME/../../files/fuel-migrate/fuel-migrate"

load "$fms"
fuel_astute="$BATS_TMPDIR/test.yaml"
fuel_migrate_vars="$BATS_TMPDIR/.var"
echo "---
ADMIN_NETWORK:
  cidr: 10.20.0.0/24
  dhcp_gateway: "172.16.58.68"
  dhcp_pool_start: "172.16.58.70"
  dhcp_pool_end: "172.16.58.92"
  interface: eth9
  ipaddress: "1.22.222.1"
  mac: "52:54:00:d6:6f:9e"
  netmask: "255.0.255.0"
  size: "256"
HOSTNAME: fuel-slab2
NTP1: 0.pool.ntp.org
">${fuel_astute}



@test "Check help message" {
    run usage
    [ $status -eq 1 ]
    [ "${lines[0]}" = "Usage:" ]
}

@test "Check usage with error notification" {
    run usage "custom message"
    [ $status -eq 1 ]
    [ "${lines[0]}" = "custom message" ]
}


@test "Check yaml parser" {
    run yaml_var $fuel_astute ADMIN_NETWORK ipaddress
    [ "${lines[0]}" = "1.22.222.1" ]
    run yaml_var $fuel_astute ADMIN_NETWORK interface
    [ "${lines[0]}" = "eth9" ]
    run yaml_var $fuel_astute ADMIN_NETWORK netmask
    [ "${lines[0]}" = "255.0.255.0" ]
}

@test "Check mytrim" {
    run mytrim   two one
    [ "${lines[0]}" = "two" ]
}

@test "Check save_vars" {
    varone=one
    run save_vars varone
    run cat ${fuel_migrate_vars}
    [ "${lines[1]}" = 'varone="one"' ]
}


@test "Check ifaces transformer" {
    other_net_bridges="eth1,br10,,ems1,virbr1,<xml test >,"
    IFS=","
    run ifaces $other_net_bridges
    IFS=" "
    [ "${lines[0]}" = "     <interface type='bridge'>" ]
    [ "${lines[1]}" = "      <source bridge='br10'/>" ]
    [ "${lines[2]}" = "      <target dev='vfm_eth1'/>" ]
    [ "${lines[3]}" = "     <model type='virtio'/>" ]
    [ "${lines[4]}" = "    </interface>" ]
    [ "${lines[5]}" = "     <interface type='bridge'>" ]
    [ "${lines[6]}" = "      <source bridge='virbr1'/>" ]
    [ "${lines[7]}" = "      <target dev='vfm_ems1'/>" ]
    [ "${lines[8]}" = "<xml test >" ]
    [ "${lines[9]}" = "     <model type='virtio'/>" ]
    [ "${lines[10]}" = "    </interface>" ]
}


@test "Check echo with indent" {

    indent="----------"
    wtw="20"
    long_long_var="   word1 word11 01234567890123456789012345 word111\
                       word1111   word11111"
    run echo_indent $long_long_var
    [ "${lines[0]}" = "---------- word1 word11" ]
    [ "${lines[1]}" = "---------- 01234567890123456789012345" ]
    [ "${lines[2]}" = "---------- word111 word1111" ]
    [ "${lines[3]}" = "---------- word11111" ]
}

@test "Check clone_part_str" {
    src_bs="512"
    dst_bs="1024"
    pcount="1"
    param="   1              34           49152   24.0 MiB    EF02  primary"
    set -- $param
    run clone_part_str $*
    [ "${lines[0]}" = " -n1:17: -t 1:EF02 -c 1:primary" ]
    pcount="2"
    run clone_part_str $*
    echo "$lines"
    [ "${lines[0]}" = " -n1:17:24576 -t 1:EF02 -c 1:primary" ]
}

@test "Check timeout" {
    max_worktime=3
    start_time=$(date +%s)
    run timeout
    [ $status -eq 0 ]
    sleep $(( ${max_worktime} + 1 ))
    run timeout
    [ $status -eq 1 ]
}

@test "Check second run lock" {
    lockfile_dir=/tmp
    fd=200
    prog_name=fuel-migrate

    run file_lock
    [ $status -eq 0 ]

# run close all descriptors
    file_lock
    fd=201
    run file_lock
    [ $status -eq 1 ]


}
